---
title: Span binary reader
summary: Span is marvelous way to represent contiguous memory in .NET. What it lacks is convenience in reading/writing using build in functions or dedicated reader/writer. Today I'll try to address the former 
publishDate: 2023-01-04
tags: [csharp, performance]
categories: [programming]
draft: false
author: Michał Bryłka
---

[Span/ReadOnlySpan](https://learn.microsoft.com/en-us/archive/msdn-magazine/2018/january/csharp-all-about-span-exploring-a-new-net-mainstay) represent marvelous way to represent contiguous memory in .NET be it managed and unmanaged resources, strings or stack-allocated values. What they lack however is convenience in reading/writing using build in functions or dedicated reader/writer. Today I'll try to address the former utility structure.

## Reader design
In order to create a wrapper around [ref-structure](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/ref-struct) we need to define ref struct as well:

``` cs
public ref struct SpanBinaryReader
{
    private readonly ReadOnlySpan<byte> _buffer;
    private int _position;

    // Current position
    public int Position => _position; 

    // Length of underlying buffer
    public int Length => _buffer.Length; 
    
    public SpanBinaryReader(ReadOnlySpan<byte> buffer, int position = 0)
    {
        _buffer = buffer;
        _position = position;
    }
}
```

In order to be familiar to developer we will try to follow [BinaryReader](https://learn.microsoft.com/en-us/dotnet/api/system.io.binaryreader?view=net-7.0) API logic by defining similar seek/position features:

``` cs
// Reset current position to default (0)
public void Reset() => _position = 0;

// Advance (or retreat) current position by given amount
// Offset parameter indicates number of bytes to advance position by 
// or retreat by in case of negative numbers
public void Seek(int offset)
{
    var newPosition = _position + offset;
    if (newPosition < 0)
        throw new ArgumentOutOfRangeException(nameof(offset), offset, 
            $"After advancing by {nameof(offset)} parameter, " + 
             "position should point to non-negative number");

    _position = newPosition;
}

// Determines if end of buffer was reached 
public bool IsEnd => _position >= _buffer.Length;
```

as well as *ReadXXX* methods:
``` cs
// Reads 1 byte from underlying stream. Returns byte read or -1 if EOB is reached
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public int ReadByte() => _position >= _buffer.Length ? -1 : _buffer[_position++];

// Reads one little endian 16 bits integer from underlying stream
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public short ReadInt16() => BinaryPrimitives.ReadInt16LittleEndian(ReadExactly(2));

// Reads one little endian 32 bits integer from underlying stream
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public int ReadInt32() => BinaryPrimitives.ReadInt32LittleEndian(ReadExactly(4));

// Reads one little endian 64 bits integer from underlying stream
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public long ReadInt64() => BinaryPrimitives.ReadInt64LittleEndian(ReadExactly(8));

// Reads boolean value from underlying stream. Returns true if byte read is non-zero, false otherwise
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public bool ReadBoolean() => ReadExactly(1) is var slice && slice[0] != 0;

// Reads one little endian 32 bits floating number from underlying stream
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public float ReadSingle() => BinaryPrimitives.ReadSingleLittleEndian(ReadExactly(4));

// Reads one little endian 64 bits floating number from underlying stream
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public double ReadDouble() => BinaryPrimitives.ReadDoubleLittleEndian(ReadExactly(8));

// Reads one little endian 128 bits decimal number from underlying stream
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public decimal ReadDecimal()
{
    int lo = ReadInt32();
    int mid = ReadInt32();
    int hi = ReadInt32();
    int flags = ReadInt32();
    return new decimal(lo, mid, hi, (flags & 0b_1000_0000_0000_0000_0000_0000_0000_0000) != 0, 
                       (byte)((flags >> 16) & 0xFF));
}
```
and remaining helper *Read* methods (code might me collapsed as it's a bit longer):
``` cs
// Reads a sequence of bytes from the current stream and advances the position within the stream by the number of bytes read.
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public int ReadTo(Span<byte> buffer)
{
    int n = Math.Min(Length - Position, buffer.Length);
    if (n <= 0)
        return 0;

    _buffer.Slice(_position, n).CopyTo(buffer);

    _position += n;
    return n;
}

// Reads buffer of given size at most
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public ReadOnlySpan<byte> Read(int numBytes)
{
    if (numBytes < 0) 
        throw new ArgumentOutOfRangeException(nameof(numBytes), 
                                              $"'{numBytes}' should be non negative");

    int n = Math.Min(Length - Position, numBytes);
    if (n <= 0)
        return ReadOnlySpan<byte>.Empty;

    var result = _buffer.Slice(_position, n);

    _position += n;

    return result;
}

// Reads buffer of exact given size 
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public ReadOnlySpan<byte> ReadExactly(int numBytes)
{
    if (numBytes < 1) 
        throw new ArgumentOutOfRangeException(nameof(numBytes), $"'{numBytes}' should be at least 1");

    int newPosition = _position + numBytes;

    if (newPosition > _buffer.Length)
        throw new ArgumentOutOfRangeException(nameof(numBytes), 
            $"Not enough data to read {numBytes} bytes from underlying buffer");

    var span = _buffer.Slice(_position, numBytes);
    _position = newPosition;
    return span;
}

// Returns remaining bytes from underlying buffer
public ReadOnlySpan<byte> Remaining() => _buffer.Slice(_position, _buffer.Length - _position);
```

## Summary 
We were able to define a utility structure that could help in easy reading of data from spans so that neither high performance nor convenience are hindered. Next time we will see how these routines can help in solving real life performance issue :rocket:.

Stay tuned for more info :vulcan_salute:. 

## Sources 
- [SpanBinaryReader sources](https://github.com/nemesissoft/Nemesis.Essentials/blob/70e1f4817654b6f16589315337e60fbd64d0c651/Nemesis.Essentials/Design/SpanBinaryReader.cs)
- [SpanBinaryReader tests](https://github.com/nemesissoft/Nemesis.Essentials/blob/70e1f4817654b6f16589315337e60fbd64d0c651/Nemesis.Essentials.Tests/SpanBinaryReaderTests.cs)
- {{< nuget Nemesis.Essentials >}} package contains SpanBinaryReader and other classes that should be contained in .NET but somehow are not
