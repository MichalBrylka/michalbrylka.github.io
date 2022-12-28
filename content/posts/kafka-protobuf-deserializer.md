---
title: Kafka Protobuf Deserializer
summary: Protobuf is very efficient serialization format. It can really open it's wings when underlying serializer is using it in optimal way.
publishDate: 2023-01-09
tags: [csharp, performance, kafka, protobuf]
categories: [programming]
draft: false
author: Michał Bryłka
---
[Protocol buffers](https://en.wikipedia.org/wiki/Protocol_Buffers) (aka. *protobuf* for short) is very efficient serialization format. Usually implementations provided by library maintainers (i.e. Protobuf ports for various frameworks) are optimal and are only getting better with time. Recently I needed to use Confluent Kafka's implementation of protobuf deserializer and to my astonishment, deserialization operation is not optimal.
Deserialization operation the one that my project needed the most as we were producing messages in off-work times but main system is consuming them in high-traffic periods. Let's see how we might remedy this issue.  

> This article is about Apache Kafka and Confluent's implementation of Protocol Buffers deserializer. It's not endorsed nor advertised by any of them. This is written for pure educational purposes. Copyrighted names, technologies and symbols belong to appropriate entities. 

## Deserializer 
Luckily for us, {{< nuget Confluent.Kafka >}} package is open source and can be found [here](https://github.com/confluentinc/confluent-kafka-dotnet). Indeed, upon inspection of [ProtobufDeserializer.cs](https://github.com/confluentinc/confluent-kafka-dotnet/blob/7c913b7da125a7e3ea0295505aeb11829dcfd408/src/Confluent.SchemaRegistry.Serdes.Protobuf/ProtobufDeserializer.cs#L97) we can suspect that our culprit are: 
- data.ToArray();
- using (var stream = new MemoryStream(array))
- using (var reader = new BinaryReader(stream))

These design decision were probably caused by the fact that there was no convenient and official API for reading data from [Span/ReadOnlySpan](https://learn.microsoft.com/en-us/archive/msdn-magazine/2018/january/csharp-all-about-span-exploring-a-new-net-mainstay). There is few unofficial ones, you can read about my approach [here]({{< ref "/posts/span-binary-reader" >}}). 

Fortunately for us, Confluent made Kafka to be really nicely composable so we can provide our own deserializer. The only thing we need to read upon deserialization are:
1. Magic byte (zero) to indicate a message with Confluent Platform framing
2. 4 byte schema ID. Since this is not needed as we know deserialized type's metadata (this can be taken from generic type) - we can safely ignore this portion of data (but stream pointer needs to move)
3. Unsigned/Signed variable-length encoded integers ([Varint](https://en.wikipedia.org/wiki/Variable-length_quantity)) that denotes array length - and then subsequently reading these indices 
4. Reading payload itself - this can be delegated to underlying Protobuf library (by Google in my/Confluent's case)

So our Deserialize method can look like that:
``` cs
public T? Deserialize(ReadOnlySpan<byte> data, bool isNull, SerializationContext context)
{
    if (isNull) return null;

    if (data.Length < 6)
        throw new InvalidDataException(
            "Expecting data framing of length 6 bytes or more but total data size is " +
            $"{data.Length} bytes");

    var spanReader = new SpanBinaryReader(data);

    var magicByte = spanReader.ReadByte();
    if (magicByte != MagicByte)
        throw new InvalidDataException(
            $"Expecting message {context.Component} with Confluent Schema Registry framing." +
            $"Magic byte was {magicByte}, expecting {MagicByte}");
    
    // A schema is not required to deserialize protobuf messages since the serialized data includes 
    // tag and type information, which is enough for the IMessage<T> implementation to deserialize 
    // the data (even if the schema has evolved). 
    // Schema Id is thus unused. Just advancing by 4 bytes is enough    
    spanReader.Seek(4); //var _schemaId = IPAddress.NetworkToHostOrder(spanReader.ReadInt32());
    
    // Read the index array length, then all of the indices. These are not needed, 
    // but parsing them is the easiest way to seek to the start of the serialized data
    // because they are varints.
    var indicesLength = _useDeprecatedFormat 
        ? (int)spanReader.ReadUnsignedVarint() 
        : spanReader.ReadVarint();

    for (int i = 0; i < indicesLength; ++i)
        if (_useDeprecatedFormat)
            spanReader.ReadUnsignedVarint();
        else
            spanReader.ReadVarint();
    
    return _parser.ParseFrom(spanReader.Remaining());
}
```

Full implementation can be found [here](https://github.com/nemesissoft/KafkaProtobufSyncOverAsyncPerf/blob/a286a1f9cc2bb084e151d677bc507b2000b97c80/KafkaDeserPerf/Deserializers/EfficientProtobufDeserializer.cs). During optimizations I've noticed that Confluent's implementation only implements`IAsyncDeserializer<>`whereas implementing`IDeserializer<>`should be sufficient - we are not doing any async work there. 

## Benchmarks 
### Unit benchmarks
[This](https://github.com/nemesissoft/KafkaProtobufSyncOverAsyncPerf/blob/6e7235e7489e67b712b4dfd326a646a0030e9417/KafkaDeserPerf/DeserializerBenchmarks.cs) benchmark tests what the performance and memory footprint of every approach are. Full results are located in the same file, let me just present excerpt for problem size equal to 10 (pay no attention to NonAlloc* benchmarks, they we just there for tests):
|         Method |         Mean |       Error |      StdDev | Ratio |   Gen 0 |  Gen 1 | Allocated |
|--------------- |-------------:|------------:|------------:|------:|--------:|-------:|----------:|
|      Confluent |  12,087.8 ns |   117.93 ns |   110.31 ns |  1.00 |  8.2779 | 0.1678 |  52,003 B |
| EfficientAsync |   4,995.7 ns |    52.32 ns |    48.94 ns |  0.41 |  0.9689 |      - |   6,080 B |
|  EfficientSync |   4,838.4 ns |    80.18 ns |    75.00 ns |  0.40 |  0.8545 |      - |   5,360 B |

Especially after presenting same data on interactive chart:
{{< echarts >}}
{
    "title": {
      "text": "Performance of deserializers\nfor Kafka using Protobuf scheme [ns]",
      "top": "1%",
      "left": "center"
    },
    "tooltip": {
      "trigger": "axis"
    },
    "legend": {
      "data": ["Confluent", "Efficient (async version)" , "Efficient (synchronous version)"],
      "top": "10%"
    },
    "grid": {
      "left": "5%",
      "right": "5%",
      "bottom": "5%",
      "top": "20%",
      "containLabel": true
    },
    "toolbox": {
      "feature": {
        "saveAsImage": {
          "title": "Save as Image"
        }
      }
    },
    "xAxis": {
      "type": "category",
      "boundaryGap": false,
      "data": ["1", "10", "100"]
    },
    "yAxis": {
      "type": "value"
    },
    "series": [
      {
        "name": "Confluent",
        "type": "line",        
        "data": [1228.1, 12087.8, 122244.2] 
      },
      {
        "name": "Efficient (async version)",
        "type": "line",        
        "data": [506.1, 4995.7, 49830.6]
      },
      {
        "name": "Efficient (synchronous version)",
        "type": "line",        
        "data": [487.4, 4838.4, 47873.2]
      }    
    ]
  }
{{< /echarts >}}

one can clearly see the trend that Confluent's implementation is adding (unnecessary) allocations and partially due to that they are significantly slower. 
Moreover, my synchronous version is *only* slightly (*"negligibly"*) faster than my async counterpart. But since there is really no point of using async here - synchronous deserializer might be our variant of choice. 

### Full operation benchmarks 
Ok we see where this is going. Performance benefits are visible but one can argue that they might not be significant. After all, Kafka internally allocates a lot of things (message itself, TopicPartitionOffset, ConsumeResult etc.). They all *clearly* would dwarf performance benefits we've just obtained. Let's measure that. [Here](https://github.com/nemesissoft/KafkaProtobufSyncOverAsyncPerf/blob/6e7235e7489e67b712b4dfd326a646a0030e9417/KafkaDeserPerf/FullDeserializerBenchmarks.cs) I tried to recreate the whole pipeline that Confluent's Kafka performs upon message deserialization. These are the results:
|         Method |        Mean |     Error |    StdDev | Ratio |   Gen 0 |  Gen 1 | Allocated |
|--------------- |------------:|----------:|----------:|------:|--------:|-------:|----------:|
|         Create |  1,049.5 ns |  18.40 ns |  26.97 ns |  1.00 |  0.9937 | 0.0019 |   6,240 B |
|      Confluent |  8,116.3 ns |  92.92 ns |  82.37 ns |  7.65 |  8.6670 | 0.1221 |  54,403 B |
| EfficientAsync |  5,137.8 ns |  96.98 ns |  99.59 ns |  4.85 |  1.3504 |      - |   8,480 B |
|  EfficientSync |  4,993.0 ns |  34.52 ns |  32.29 ns |  4.71 |  1.2360 |      - |   7,760 B | 

*Create* benchmark is there just to demonstrate amount of memory/performance that deserialize operation would have without any calls to Protobuf deserializer. Again, the difference both in performance and memory allocations is clear...  

## Summary 
We've demonstrated that eliminating allocations allows us to harvest low hanging fruits in performance realm. We are using this deserializer on production and it seem's fine. I&nbsp;did not prepare any Nuget package with that solution but can provide one if the need arrives. I filed an [issue](https://github.com/confluentinc/confluent-kafka-dotnet/issues/1701) and offered a pull request. So far a claim was offered that *at some point in the future this might be implemented*. Fingers crossed. Upvote :thumbsup: if you care to include my change in official release.  
Subscribe to this issue on Github to stay tuned for more info :vulcan_salute:. 

## Sources 
- [EfficientProtobufDeserializer](https://github.com/nemesissoft/KafkaProtobufSyncOverAsyncPerf/blob/a286a1f9cc2bb084e151d677bc507b2000b97c80/KafkaDeserPerf/Deserializers/EfficientProtobufDeserializer.cs) 
- [Tests](https://github.com/nemesissoft/KafkaProtobufSyncOverAsyncPerf/blob/6e7235e7489e67b712b4dfd326a646a0030e9417/Tests/EfficientProtobufDeserializerTests.cs)