---
title: With method for non record types
summary: The with keyword in C# allows for the creation of new instances of record types with modified properties. It is however exclusive to record types. This article tries to address that issue. 
publishDate: 2024-08-02
tags: [csharp, records]
categories: [programming]
draft: false
author: Michał Bryłka
---

The [with](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/with-expression) keyword in C# is a relatively recent addition to the language, introduced with C# 9.0. It is a feature that provides a concise and convenient way to create a new object based on an existing object, with some properties changed. This feature is particularly useful when working with immutable objects, such as records, where you cannot modify the object's state directly after its creation. It is however exclusive to record types. This article tries to address that issue. 

## Utility method 
Have a look at the following method. `Property.Of`method can be used from [Nemesis.EssentialsTypeMeta.Sources](https://www.nuget.org/packages/Nemesis.Essentials.TypeMeta.Sources) source package.

``` cs
public static TObject With<TObject, TProp>(this TObject settings, Expression<Func<TObject, TProp>> propertyExpression, TProp newValue)
    where TObject : ISettings
{
    static bool EqualNames(string s1, string s2) => string.Equals(s1, s2, StringComparison.OrdinalIgnoreCase);

    var property = Property.Of(propertyExpression);
    var ctor = typeof(TObject).GetConstructors().Select(c => (Ctor: c, Params: c.GetParameters()))
        .Where(pair =>
            pair.Params.Length > 0 &&
            pair.Params.Any(p => EqualNames(p.Name, property.Name))
        )
        .OrderByDescending(p => p.Params.Length)
        .FirstOrDefault().Ctor ?? throw new NotSupportedException("No suitable constructor found");

    var allProperties =
        typeof(TObject).GetProperties(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);

    object GetArg(string paramName)
    {
        if (EqualNames(paramName, property.Name))
            return newValue;
        else
        {
            var prop = allProperties.FirstOrDefault(p => EqualNames(paramName, p.Name))
                ?? throw new NotSupportedException($"No suitable property found: {paramName} +/- letter casing");
            var value = prop.GetValue(settings);
            return value;
        }
    }

    var arguments = ctor.GetParameters()
        .Select(p => GetArg(p.Name)).ToArray();

    return (TObject)ctor.Invoke(arguments);
}

public static class Property
{
    public static PropertyInfo Of<TType, TProp>(Expression<Func<TType, TProp>> memberExpression)
    {
        if (memberExpression.Body is MemberExpression { Member: PropertyInfo property })
            return property;
        else if (memberExpression.Body.NodeType == ExpressionType.Convert &&
                 memberExpression.Body is UnaryExpression { Operand: MemberExpression { Member: PropertyInfo property2 } })
            return property2;
        else
            throw new ArgumentException(@"Only member (property) expressions are valid at this point. Unable to determine property info from expression.", nameof(memberExpression));
    }
}
```


## Example 
Consider the following example class along with sample program

``` cs
#nullable disable
using System;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;


public class Program {
    public static void Main() {
        var settings = CollectionSettings.Default;
        Console.WriteLine(settings);
        //settings.DefaultCapacity = 15; //not possible
        var newSettings = settings.With<CollectionSettings, byte?>(s => s.DefaultCapacity, 15);
        Console.WriteLine(newSettings);
        
        Console.WriteLine(settings); //settings variable is not changed
    }
}

public sealed class CollectionSettings
{
    public char ListDelimiter { get; private set; }
    public char NullElementMarker { get; private set; }
    public char EscapingSequenceStart { get; private set; }
    public char? Start { get; private set; }
    public char? End { get; private set; }
    public byte? DefaultCapacity { get; private set; }

    public CollectionSettings(
        char listDelimiter = '|',
        char nullElementMarker = '∅',
        char escapingSequenceStart = '\\',
        char? start = null,
        char? end = null,
        byte? defaultCapacity = null)
    {
        ListDelimiter = listDelimiter;
        NullElementMarker = nullElementMarker;
        EscapingSequenceStart = escapingSequenceStart;
        Start = start;
        End = end;
        DefaultCapacity = defaultCapacity;        
    }

    public static CollectionSettings Default { get; } = new();
    
    public override string ToString() => $"@{GetHashCode()} {Start}Item1{ListDelimiter}Item2{ListDelimiter}…{ListDelimiter}ItemN{End} escaped by '{EscapingSequenceStart}', null marked by '{NullElementMarker}'. DefaultCapacity = {DefaultCapacity}";
}

```


## Summary 
While not perfect, using`With`method one can achieve similar semantics that`with`keyword offers :rocket:.



## Sources 
- [Example sources](https://gist.github.com/MichalBrylka/ca5f0c430b13a4af6394cd94735cf0bf)
- [sharplab example](https://sharplab.io/#v2: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)
- {{< nuget Nemesis.Essentials.TypeMeta.Sources >}} package contains`Property.Of`and other runtime/reflection helpers 