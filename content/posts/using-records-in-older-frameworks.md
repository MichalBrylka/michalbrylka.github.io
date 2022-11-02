---
title: Using Records in legacy .NET Frameworks
summary: C# 9.0 records can be used in older frameworks. Extend your score on records to [100]/[100]
date: 2020-06-11T00:18:08+02:00
tags: ["records", legacy]
categories:
  - csharp
draft: false
author: Michał Bryłka
---

Recenly we've been seeing an increased activities on various blogs due to upcoming .NET 5 release date and one of it's hottest feature - C# 9.0 records. 
A lot was written about this feature, starting with [MSDN](https://devblogs.microsoft.com/dotnet/welcome-to-c-9-0/). 

What was not clear however, was whether one can use records in older frameworks - like .NET 4.8. 


## Anatomy of init-only properties 
Let's settle our attention on the following example
```csharp
record Vertebrate(string Name)
{
    public Vertebrate() : this("") { }
}

public enum Habitat { Terrestrial, Aquatic, Amphibian }

public record Reptile(Habitat Habitat) : Vertebrate { }
```

Upon compilation under net5.0 framework moniker, everything works as expected. Change it to however to net48 and you will not be able to compile it. This compiler feature fortunatelly works like opt-in member resolution (similarly to string interpolation). What compiler needs in this case is an accessible class of the following structure  
```csharp
//TODO: use appropriate compiler directives for legacy targets - it's not needed in net5.0
#if NETSTANDARD2_0
namespace System.Runtime.CompilerServices
{
    [System.ComponentModel.EditorBrowsable(System.ComponentModel.EditorBrowsableState.Never)]
    internal static class IsExternalInit { }
}
#endif

```

### Check if property is init-only
After quick research one can spot that init-only setter has special structure:
```
.set instance void modreq([System.Runtime]System.Runtime.CompilerServices.IsExternalInit)
  DotnetCommunityDemoNet5.Records/Vertebrate::set_Name(string)
```

To determine that setter is init-only one just needs to query the existence of required modifier initialized with aforementioned IsExternalInit type - this code helper should do the trick:
```csharp
public static class RecordsHelper
{
    public static bool IsInitOnly(this PropertyInfo property) =>
        property.CanWrite && property.SetMethod is var setter
            && setter.ReturnParameter.GetRequiredCustomModifiers() is var reqMods 
            && reqMods.Length > 0
            && Array.IndexOf(reqMods, typeof(System.Runtime.CompilerServices.IsExternalInit)) > -1;
}
```

## Consuming records in older frameworks 
{{< admonition tip "Tip" true >}}
Records are not any special types - they are, per se, not specially recognized by CLI/CLR. They are just spcially designed classes with: 
- init only properties (default behaviour for positional records)
- authomatic structural equality, IEquatable<> implementation, equality operators
- positional [deconstruction](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/functional/deconstruct)
- printing/formatting
{{< /admonition >}}

Due to this phenomenon, consuming records is quite straightforward - you are using them as normal classes. If you'd like to use [__with__](https://devblogs.microsoft.com/dotnet/welcome-to-c-9-0/#with-expressions) keyword then you need to use C# 9.0+ for instance by specifying that in *.csproj file:
```xml
<PropertyGroup>
    <LangVersion>9.0</LangVersion>
</PropertyGroup>
``` 

## Sources 
- [Records producer/consumer](https://gist.github.com/MichalBrylka/417672620d1305de4a6db68698302544)