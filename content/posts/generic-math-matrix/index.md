---
title: Generic math extended example
summary: Generic math feature from C# 11 brings us a lot of flexibility. Besides ubiquitously shared simple generic methods we can also implement whole types. Matrix seems to be a good candidate 
publishDate: 2022-12-05T00:00:00+01:00
tags: ["language", math, generics, csharp]
categories: [programming]
draft: false
math: true
author: Michał Bryłka

resources:
- name: "featured-image"
  src: "featured-image.png"

#lightgallery: true
---

C# 11.0 [generic math](https://devblogs.microsoft.com/dotnet/preview-features-in-net-6-generic-math/) is very powerful extension to already capable generic types system present in C# since version 2.0. Besides [static interface members]({{< ref "/posts/static-interface-members" >}} "Static Interface Members") there are couple of changes that make it easier to express math concepts in C#. Let's see what needed to change in order to add this neat feature.

{{< admonition type=note title="Note" open=true >}}
This blog post participates in [C# Advent Calendar 2022](https://csadvent.christmas/). Expect around 50 awesome posts this month, with 2 being revealed every day. It's digital/C#-oriented counterpart of old [German tradition](https://en.wikipedia.org/wiki/Advent_calendar)
{{< /admonition >}}


## Interfaces and operations
While generic math is C# 11 feature, there were some new additions in .NET framework itself. In order to facilitate appropriate abstraction, the following interfaces were introduced and numeric/built-in types subsequently started implementing them:
| Interface                                                                                 | Description                                                                          |
| ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| [INumberBase](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.inumberbase-1) | Base interface for all numbers                                                       |
| [INumber](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.inumber-1)         | All members related to numbers. Extends INumberBase mostly for comparison operations |
| IParseable                                                                                | Parse(string, IFormatProvider)                                                       |
| ISpanParseable                                                                            | Parse(ReadOnlySpan<char>, IFormatProvider)                                           |
| IAdditionOperators                                                                        | x + y                                                                                |
| IBitwiseOperators                                                                         | x & y, x &#124; y, x ^ y and ~x                                                      |
| IComparisonOperators                                                                      | x < y, x > y, x <= y, and x >= y                                                     |
| IDecrementOperators                                                                       | --x and x--                                                                          |
| IDivisionOperators                                                                        | x / y                                                                                |
| IEqualityOperators                                                                        | x == y and x != y                                                                    |
| IIncrementOperators                                                                       | ++x and x++                                                                          |
| IModulusOperators                                                                         | x % y                                                                                |
| IMultiplyOperators                                                                        | x * y                                                                                |
| IShiftOperators                                                                           | x << y and x >> y                                                                    |
| ISubtractionOperators                                                                     | x - y                                                                                |
| IUnaryNegationOperators                                                                   | -x                                                                                   |
| IUnaryPlusOperators                                                                       | +x                                                                                   |
| IAdditiveIdentity                                                                         | (x + T.AdditiveIdentity) == x                                                        |
| IMinMaxValue                                                                              | T.MinValue and T.MaxValue                                                            |
| IMultiplicativeIdentity                                                                   | (x * T.MultiplicativeIdentity) == x                                                  |
| IBinaryFloatingPoint                                                                      | Members common to binary floating-point types                                        |
| IBinaryInteger                                                                            | Members common to binary integer types                                               |
| IBinaryNumber                                                                             | Members common to binary number types                                                |
| IFloatingPoint                                                                            | Members common to floating-point types                                               |
| INumber                                                                                   | Members common to number types                                                       |
| ISignedNumber                                                                             | Members common to signed number types                                                |
| IUnsignedNumber                                                                           | Members common to unsigned number types                                              |

List of all of them can be found on [MSDN](https://learn.microsoft.com/en-us/dotnet/api/system.numerics?view=net-7.0#interfaces)

## Checked operators
In C# 11 it is now possible to specify operators as checked. Compiler will select appropriate version depending on context (Visual Studio will navigate to appropriate operator definition upon pressing {{< raw >}}<kbd>F12</kbd>{{< /raw >}}/"Go to definition"). Let's see that on example:
``` csharp
readonly record struct Point(int X, int Y)
{
    public static Point operator checked +(Point left, Point right) =>
        checked(new(left.X + right.X, left.Y + right.Y));

    public static Point operator +(Point left, Point right) =>
        new(left.X + right.X, left.Y + right.Y);
}

//usage
var point = new Point(int.MaxValue - 1, int.MaxValue - 2); //Point { X = 2147483646, Y = 2147483645 }

var @unchecked = unchecked(point + point); //Point { X = -4, Y = -6 }
var @checked = checked(point + point); //⚠️ throws System.OverflowException

```

## Identity element and constants
Every number type usually (always for C# numbers but that is not necessarily the case in math) has some identity elements for most popular operations (addition and multiplication). The following listing demonstrates them using generic guard as these constants are not publicly exposed 
``` csharp
private static void Constants<T>() where T : INumber<T>
{
    var one = T.One;
    var zero = T.Zero;
    var additiveIdentity = T.AdditiveIdentity;
    var multiplicativeIdentity = T.MultiplicativeIdentity;
}
```

## Conversions
In order to be able to smoothly convert numbers from other number types, several methods were added:
- _CreateChecked_ - convert "exactly" or throw if number falls outside the representable range
- _CreateSaturating_ - convert values saturating any values that fall outside the representable range 
- _CreateTruncating_ - convert values truncating any values that fall outside the representable range
``` csharp
//specifying generic type is not needed, it's just here for clarity 
var b1 = byte.CreateSaturating<int>(300); //255
var b2 = byte.CreateTruncating(300); //44
var b3 = byte.CreateChecked(300); //⚠️ Arithmetic operation resulted in an overflow.
var b4 = byte.CreateChecked(3.14); //3
```

## Dedicated functions 
New function were introduced to built-in types to facilitate typical operation that we perform with given number groups.  
``` csharp
//Check if integer is power of two. Equivalent to BitOperations.IsPow2(1024) 
var isPow = int.IsPow2(1024); // true

//Population count (number of bits set). Same as BitOperations.PopCount(15) - vectorized if possible 
var pop = int.PopCount(15); // 4

//Cubic root of a specified number. Equivalent to MathF.Cbrt(x)
var cbrt = float.Cbrt(8.0f); // 2

//Sine of the specified angle (in radians). Equivalent to MathF.Sin(x)
var sin = float.Sin(float.Pi / 6.0f); //0.5
```
For more functions see list for [integers](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.ibinaryinteger-1?view=net-7.0#methods) or [floating point numbers](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.ifloatingpointieee754-1?view=net-7.0#methods). Other interesting function groups are:
- [ITrigonometricFunctions](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.itrigonometricfunctions-1?view=net-7.0#methods)
- [IRootFunctions](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.irootfunctions-1?view=net-7.0#methods)
- [IPowerFunctions](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.ipowerfunctions-1?view=net-7.0#methods)
- [ILogarithmicFunctions](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.ilogarithmicfunctions-1?view=net-7.0#methods)

## Matrix definition
We are now ready to propose a new type that will denote a generic matrix of number-like structures. Make sure to read a post about [static interface members]({{< ref "/posts/static-interface-members" >}} "Static Interface Members") if that concept is still new to you. 

### Structure
Let's start with simple definition. Just for fun we will be restricting our number generic parameter to [unmanaged types](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/unmanaged-types). This is not strictly needed for our example but it will allow for some tricks like faster array enumeration 
``` csharp
public partial class Matrix<TNumber> //for now we are not extending any interface
       where TNumber : unmanaged //needed for pointer "magic"
{
    private readonly TNumber[,] _data;
    public int Rows { get; }
    public int Columns { get; }
    public int Size { get; }

    public TNumber this[int iRow, int iCol] => _data[iRow, iCol];

    public Matrix(TNumber[,] data)
    {
        _data = data;
        Rows = data.GetLength(0);
        Columns = data.GetLength(1);
        Size = Rows * Columns;
    }
     
    //optionally we'd like to be able to create Matrix using 1-D array with certain number of columns 
    public unsafe Matrix(TNumber[] data, int columns)
    {
        var data2d = new TNumber[data.Length / columns, columns];
        
        fixed (TNumber* pSource = data, pTarget = data2d)
        {
            for (int i = 0; i < data.Length; i++)
                pTarget[i] = pSource[i];
        }
        _data = data2d;
        Rows = data2d.GetLength(0);
        Columns = data2d.GetLength(1);
    }
}
```

### Matrix operations 
While this class already is able to store some data, we would not be able to do anything meaningful with it. Let's add our first math operation - addition. Since that operation uses only addition and needs to be seeded with zero (additive identity) we could modify our generic guard to:
``` csharp
class Matrix
    where TNumber : unmanaged, 
        IAdditionOperators<TNumber, TNumber, TNumber>,
        IAdditiveIdentity<TNumber, TNumber>
{ 
    /*...*/
    public unsafe TNumber Sum()
    {
       var result = TNumber.AdditiveIdentity;
       fixed (TNumber* pData = _data) //use pointers to be able to iterate array faster 
       {
           var p = pData;
           for (int i = 0; i < Size; i++)
               result += *p++;
       }    
       return result;
    }
}
``` 
but we would be better off when that guard would be changed to 
``` csharp
public partial class Matrix<TNumber>
    where TNumber : unmanaged, 
    //it is just necessary to mark number type appropriately to be able to use it in generic contexts
        INumberBase<TNumber> 
{
    /*...*/
    public unsafe TNumber Sum()
    {
        //"Zero" also looks more natural in that context as opposed to "AdditiveIdentity"
        var result = TNumber.Zero; 
        fixed (TNumber* pData = _data)
        {
            var p = pData;
            for (int i = 0; i < Size; i++)
                result += *p++;
        }
        return result;
    }
}
```

Summation is obviously useful but it's also trivial in it's form. For instance let's consider C# whole number types. Like in math, [natural](https://en.wikipedia.org/wiki/Natural_number) and [integer](https://en.wikipedia.org/wiki/Integer) numbers are [closed](https://en.wikipedia.org/wiki/Closure_(mathematics)) under addition. When you consider other operations on these numbers, say division, this is no longer the case. While we could calculate an average of integers in C# as follows
``` csharp
var intArray = new[] { 1, 2, 4 };
var avg = intArray.Sum() / intArray.Length; //2
```
it would be more convenient to convert result and intermediate operations to floating point numbers. Even LINQ function does that:
``` csharp
var avgLinq = intArray.Average(); //2.3333333333333335
```

This conversion will do the trick for our matrix:
``` csharp
public unsafe TResult Sum<TResult>() where TResult : INumber<TResult>
{
    var result = TResult.Zero;
    fixed (TNumber* pData = _data)
    {
        var p = pData;
        for (int i = 0; i < Size; i++)
            result += TResult.CreateChecked(*p++);
    }
    return result;
}

// now Average can use Sum<TResult>
public TResult Average<TResult>() where TResult : INumber<TResult>
{
    TResult sum = Sum<TResult>();
    return sum / TResult.CreateChecked(Size);
}
```
No matrix is complete without [Determinant](https://en.wikipedia.org/wiki/Determinant) function. While there are dozens of algorithms to do that, I'll use a&nbsp;plain decomposition approach due to it's simplicity
``` csharp
public TNumber Determinant()
{
    if (Rows != Columns) throw new("Determinant of a non-square matrix doesn't exist");

    var det = TNumber.Zero;

    if (Rows == 1) return this[0, 0];
    if (Rows == 2) return this[0, 0] * this[1, 1] - this[0, 1] * this[1, 0];

    for (int j = 0; j < Columns; j++)
    {
        TNumber reduced = this[0, j] * Minor(0, j).Determinant();
        if (j % 2 == 1)
            reduced = -reduced;
        det += reduced;
    }
    return det;
}
public Matrix<TNumber> Minor(int iRow, int iCol)
{
    var minor = new TNumber[Rows - 1, Columns - 1];
    int m = 0;
    for (int i = 0; i < Rows; i++)
    {
        if (i == iRow)
            continue;
        int n = 0;
        for (int j = 0; j < Columns; j++)
        {
            if (j == iCol)
                continue;
            minor[m, n] = this[i, j];
            n++;
        }
        m++;
    }
    return new(minor);
}
```
Similarly it might be useful to obtain largest and smallest element in matrix. Since that requires some comparisons, let's add `IComparisonOperators<TNumber, TNumber, bool>` interface to our generic guard for `TNumber`. Doing so enables us to then use comparison operators. We will however lose (as a consequence) the ability of using types that do not possess relational ordering - [Complex](https://learn.microsoft.com/en-us/dotnet/api/system.numerics.complex?view=net-7.0) type being most notable here
{{< admonition type=note title="Note" open=true >}}
Using `IComparisonOperators<TNumber, TNumber, bool>` is somewhat limiting. It's probably more important to be able to use final matrix with types like Complex especially if Min/Max operation could be added using different approach. So final design of matrix might reflect that notion
{{< /admonition >}}

``` csharp
public unsafe TNumber Min()
{
    if (Size == 0) throw new("Matrix is empty");

    TNumber result;
    fixed (TNumber* pData = _data)
    {
        var p = pData;
        result = *p;

        for (int i = 1; i < Size; i++)
            result = Min(result, *p++);
    }

    return result;

    static TNumber Min(TNumber x, TNumber y)
    {
        if ((x != y) && !TNumber.IsNaN(x))
            return x < y ? x : y;
        return TNumber.IsNegative(x) ? x : y;
    }
}

public unsafe TNumber Max()
{
    if (Size == 0) throw new("Matrix is empty");

    TNumber result;
    fixed (TNumber* pData = _data)
    {
        var p = pData;
        result = *p;

        for (int i = 1; i < Size; i++)
            result = Max(result, *p++);
    }

    return result;

    static TNumber Max(TNumber x, TNumber y)
    {
        if (x != y)
            return TNumber.IsNaN(x) ? x : y < x ? x : y;
        return TNumber.IsNegative(y) ? x : y;
    }
}
```

### Matrix operators 
Have a look at the following operators (code example might need expanding):
``` csharp
//add 2 matrices
public unsafe static Matrix<TNumber> operator +(Matrix<TNumber> left, Matrix<TNumber> right)
{
    if (left.Rows != right.Rows || left.Columns != right.Columns) throw new("Sum of 2 matrices is only possible when they are same size");

    var data = new TNumber[left.Rows, left.Columns];
    var size = left.Rows * left.Columns;

    fixed (TNumber* lSource = left._data, rSource = right._data, target = data)
    {
        for (int i = 0; i < size; i++)
            target[i] = lSource[i] + rSource[i]; //checked operator version would differ only in this line
    }

    return new Matrix<TNumber>(data);
}

//right-side operator for adding single number element-wise
public unsafe static Matrix<TNumber> operator +(Matrix<TNumber> left, TNumber right)
{
    var data = new TNumber[left.Rows, left.Columns];
    var size = left.Rows * left.Columns;

    fixed (TNumber* lSource = left._data, target = data)
    {
        for (int i = 0; i < size; i++)
            target[i] = lSource[i] + right;
    }

    return new Matrix<TNumber>(data);
}
// Multiplication. More efficient function might be chosen for production code. 
// This is just to illustrate this operator
public static Matrix<TNumber> operator *(Matrix<TNumber> a, Matrix<TNumber> b)
{
    int rowsA = a.Rows, colsA = a.Columns, rowsB = b.Rows, colsB = b.Columns;

    if (colsA != rowsB) throw new("Matrixes can't be multiplied");

    var data = new TNumber[rowsA, colsB];

    for (int i = 0; i < rowsA; i++)
    {
        for (int j = 0; j < colsB; j++)
        {
            var temp = TNumber.Zero;
            for (int k = 0; k < colsA; k++)
                temp += a[i, k] * b[k, j];

            data[i, j] = temp;
        }
    }
    return new Matrix<TNumber>(data);
}
```

### Parsing
No math structure is complete without parsing and formatting routines. We would like to support multiple matrix definition formats like:
 - Matlab: `[1,2,3 ; 4,5,6 ; 7,8,9]`
 - Mathematica: `{{1,2,3},{4,5,6},{7,8,9}}`
 - natural notation:
{{< raw >}}
$$
\begin{matrix}
1 & 2 & 3\\
4 & 5 & 6\\
7 & 8 & 9
\end{matrix}
$$
{{< /raw >}}

The code below might do the trick (full code is linked at the end of current article):
``` csharp
/// <summary>Parsing and formatting operation for matrices</summary>
public interface IMatrixTextFormat
{
    /// <summary>
    /// Parse matrix from text buffer 
    /// </summary>    
    Matrix<TNumber> Parse<TNumber>(ReadOnlySpan<char> s)
        where TNumber : unmanaged, IComparisonOperators<TNumber, TNumber, bool>, INumberBase<TNumber>;

    /// <summary>
    /// Attempt to format current matrix in provided text buffer
    /// </summary>        
    bool TryFormat<TNumber>(Matrix<TNumber> matrix, Span<char> destination, out int charsWritten, 
                            ReadOnlySpan<char> format)
        where TNumber : unmanaged, IComparisonOperators<TNumber, TNumber, bool>, INumberBase<TNumber>;
}

public readonly struct StandardFormat : IMatrixTextFormat
{
    private readonly IFormatProvider _underlyingProvider;
    private readonly NumberStyles? _numberStyles;
    private readonly char _elementSeparator;

    private static readonly char[] _rowSeparators = Environment.NewLine.ToCharArray();

    public StandardFormat() : this(CultureInfo.InvariantCulture) { }

    public StandardFormat(IFormatProvider? underlyingProvider, 
                          NumberStyles numberStyles = NumberStyles.Any)
    {
        _numberStyles = numberStyles;
        _underlyingProvider = underlyingProvider ?? CultureInfo.InvariantCulture;

        (_underlyingProvider, _elementSeparator) = GetParameters();
    }

    private (IFormatProvider Provider, char ElementSeparator) GetParameters()
    {
        var provider = _underlyingProvider ?? CultureInfo.InvariantCulture;
        char elementSeparator = _elementSeparator != '\0'
            ? _elementSeparator
            : (provider is CultureInfo ci ? ci.TextInfo.ListSeparator.Trim().Single() : ';');

        return (provider, elementSeparator);
    }

    public Matrix<TNumber> Parse<TNumber>(ReadOnlySpan<char> s)
        where TNumber : unmanaged, IComparisonOperators<TNumber, TNumber, bool>, INumberBase<TNumber>
    {
        var (provider, elementSeparator) = GetParameters();
        var numberStyles = _numberStyles ?? NumberStyles.Any;

        var rowsEnumerator = s.Split(_rowSeparators, true).GetEnumerator();
        if (!rowsEnumerator.MoveNext()) throw new FormatException("Non empty text is expected");
        var firstRow = rowsEnumerator.Current;
        int numCols = 0;

        using var buffer = new ValueSequenceBuilder<TNumber>(stackalloc TNumber[32]);
        foreach (var col in firstRow.Split(elementSeparator, true))
        {
            if (col.IsEmpty) continue;
            buffer.Append(TNumber.Parse(col, numberStyles, provider));
            numCols++;
        }
        int numRows = 1;

        while (rowsEnumerator.MoveNext())
        {
            var row = rowsEnumerator.Current;
            if (row.IsEmpty) continue;

            foreach (var col in row.Split(elementSeparator, true))
            {
                if (col.IsEmpty) continue;
                buffer.Append(TNumber.Parse(col, numberStyles, provider));
            }
            numRows++;
        }
        var matrix = new TNumber[numRows, numCols];

        buffer.AsSpan().CopyTo2D(matrix);

        return new Matrix<TNumber>(matrix);
    }

    public bool TryFormat<TNumber>(Matrix<TNumber> matrix, Span<char> destination, 
                                   out int charsWritten, ReadOnlySpan<char> format)
        where TNumber : unmanaged, IComparisonOperators<TNumber, TNumber, bool>, INumberBase<TNumber>
    {
        var (provider, elementSeparator) = GetParameters();

        var newLine = _rowSeparators.AsSpan();
        var newLineLen = newLine.Length;
        int charsWrittenSoFar = 0;

        for (int i = 0; i < matrix.Rows; i++)
        {
            for (int j = 0; j < matrix.Columns; j++)
            {
                bool tryFormatSucceeded = matrix[i, j].TryFormat(destination[charsWrittenSoFar..], 
                    out var tryFormatCharsWritten, format, provider);
                charsWrittenSoFar += tryFormatCharsWritten;

                if (!tryFormatSucceeded)
                {
                    charsWritten = charsWrittenSoFar;
                    return false;
                }

                if (j < matrix.Columns - 1)
                {
                    if (destination.Length < charsWrittenSoFar + 2)
                    {
                        charsWritten = charsWrittenSoFar;
                        return false;
                    }

                    destination[charsWrittenSoFar++] = elementSeparator;
                    destination[charsWrittenSoFar++] = ' ';
                }
            }

            if (i < matrix.Rows - 1)
            {
                if (destination.Length < charsWrittenSoFar + newLineLen)
                {
                    charsWritten = charsWrittenSoFar;
                    return false;
                }

                newLine.CopyTo(destination[charsWrittenSoFar..]);
                charsWrittenSoFar += newLineLen;
            }
        }

        charsWritten = charsWrittenSoFar;
        return true;
    }
}
``` 

## Beyond standard number types 
So far we've assumed (quite correctly) that only types that implement `INumberBase<TNumber>` interface are built&#8209;in system number types. Let's quickly implement a rational/fraction structure and see how it can be used in our matrix. For brevity I'm only providing/implementing formatting routines (stay tuned for more functionality):
```cs
public readonly record struct Rational<TNumber>(TNumber Numerator, TNumber Denominator) : IEquatable<Rational<TNumber>>, IComparisonOperators<Rational<TNumber>, Rational<TNumber>, bool>,
     INumberBase<Rational<TNumber>>
     where TNumber : IBinaryInteger<TNumber> //make sense to allow only integers for numerator and denominator
{
    public static Rational<TNumber> Zero => new(TNumber.Zero, TNumber.One);
    public static Rational<TNumber> One => new(TNumber.One, TNumber.One);
    public static Rational<TNumber> AdditiveIdentity => Zero;
    public static Rational<TNumber> MultiplicativeIdentity => One;
    public static int Radix => TNumber.Radix;

    public Rational() : this(TNumber.Zero, TNumber.One) { }

    public Rational<TNumber> Simplify()
    {
        var (num, denom) = this;
        int signNum = TNumber.Sign(num), signDenom = TNumber.Sign(denom);

        if (signDenom < 0 && (signNum < 0 || signNum > 0))
        {
            num = -num;
            denom = -denom;
        }

        if (num == TNumber.Zero || num == TNumber.One || num == -TNumber.One) return this;

        var gcd = GreatestCommonDivisor(num, denom);
        return gcd > TNumber.One ? new Rational<TNumber>(num / gcd, denom / gcd) : this;
    }

    private static TNumber GreatestCommonDivisor(TNumber a, TNumber b) => b == TNumber.Zero ? a : GreatestCommonDivisor(b, a % b);

    private static readonly string TopDigits = "⁰¹²³⁴⁵⁶⁷⁸⁹";
    private static readonly string BottomDigits = "₀₁₂₃₄₅₆₇₈₉";
    private static readonly char TopMinus = '⁻';
    private static readonly char BottomMinus = '₋';
    private static readonly char Divider = '⁄';

    public bool TryFormat(Span<char> destination, out int charsWritten, ReadOnlySpan<char> format, IFormatProvider? provider)
    {
        var (num, denom) = this;
        int signNum = TNumber.Sign(num), signDenom = TNumber.Sign(denom);

        if (signDenom < 0 && (signNum < 0 || signNum > 0))
        {
            num = -num;
            denom = -denom;
        }

        provider ??= CultureInfo.InvariantCulture;

        charsWritten = 0;

        if (destination.Length < 3) return false;

        bool tryFormatSucceeded = num.TryFormat(destination, out var tryFormatCharsWritten, format, provider);
        charsWritten += tryFormatCharsWritten;
        if (!tryFormatSucceeded || destination.Length < charsWritten + 2) return false;
        var numBlock = destination[..charsWritten];
        for (int i = 0; i < numBlock.Length; i++)
        {
            var c = numBlock[i];
            if (!IsSimpleDigit(c) && c != '-') return false;
            numBlock[i] = c == '-' ? TopMinus : TopDigits[c - '0'];
        }


        if (destination.Length < charsWritten + 2) return false;
        destination[charsWritten++] = Divider;


        tryFormatSucceeded = denom.TryFormat(destination[charsWritten..], out tryFormatCharsWritten, format, provider);
        var startOfDenomBlock = charsWritten;
        charsWritten += tryFormatCharsWritten;

        if (!tryFormatSucceeded)
            return false;

        var denomBlock = destination.Slice(startOfDenomBlock, tryFormatCharsWritten);
        for (int i = 0; i < denomBlock.Length; i++)
        {
            var c = denomBlock[i];
            if (!IsSimpleDigit(c) && c != '-') return false;
            denomBlock[i] = c == '-' ? BottomMinus : BottomDigits[c - '0'];
        }

        return true;

        static bool IsSimpleDigit(char c) => (uint)c < 128 && (uint)(c - '0') <= '9' - '0';
    }

    public string ToString(string? format, IFormatProvider? formatProvider) => this.FormatToString(format, formatProvider);

    public override string? ToString() => ToString("G", null);

    /*... remaining code omitted for brevity*/
}
```

Now we can use `Rational` structure in our matrix:
```cs
var rationalMatrix = new Matrix<Rational<int>>(
    Enumerable.Range(1, 9).Select(i => new Rational<int>(
        i * 10 * (i % 2 == 0 ? 1 : -1),
        //--------------------------------
        i * 123
        ))
    .ToArray(),
    3);

//formatting of matrix delegates element formatting to Rational struct 
var text = rationalMatrix.ToString(); 
```
This will produce the following output:

{{< raw >}}
$$
\begin{matrix}
⁻¹⁰⁄₁₂₃ &  ²⁰⁄₂₄₆ & ⁻³⁰⁄₃₆₉\\
⁴⁰⁄₄₉₂  & ⁻⁵⁰⁄₆₁₅ &  ⁶⁰⁄₇₃₈\\
⁻⁷⁰⁄₈₆₁ &  ⁸⁰⁄₉₈₄ & ⁻⁹⁰⁄₁₁₀₇
\end{matrix}
$$
{{< /raw >}}


## Performance 
Code "performance" is ambiguous term. It may refer to both ease/speed of development of given feature or how said feature behaves during program runtime. Let me address the former one first as it may be easier to demonstrate

### Speed of development 
Some time ago I've create _generic_ [predictor](https://github.com/nemesissoft/SimpleLogisticRegression/tree/main) that used [logistic regression](https://en.wikipedia.org/wiki/Logistic_regression). In that context _"generic"_ meant that it was not dedicated and could be used to solve any binary classification problem (while being universal enough that same mechanism might be employed for multi-class classification). 

I decided to introduce generic math to this predictor as users may then opt to use, say, different floating point number type (like`System.Single`or`System.Half`) when it will give them similar results (for certain problems this really might be the case) but with smaller memory footprint and faster processing times. All that conversion was done on separate [branch](https://github.com/nemesissoft/SimpleLogisticRegression/tree/feature/GenericMath). 

One can observe that merely a few [changes](https://github.com/nemesissoft/SimpleLogisticRegression/compare/main...feature/GenericMath) needed to be applied. Conversion took me not more than 5 minutes. Had this coding be done with generic math in mind from the beginning - impact would have probably been even more negligible - provided that generic math is a concept known by developer (learning curve tends to be steep here)

### Runtime performance  
Have a look at my proposal of a simple vector structures. Among them you will find dedicated version for _LongVector_ (not embedded here for brevity) and dedicated version for _System.Double_:
{{< gist MichalBrylka 19ae10e62d55ce7cbb2cc9ab21e7e879 DoubleVector.cs>}}

Below you will find version that uses generic math along with version that uses generic math in tandem with pointer arithmetics ([Vector2.cs](https://gist.github.com/MichalBrylka/19ae10e62d55ce7cbb2cc9ab21e7e879#file-othervectors-cs) and others were not embedded for brevity):
{{< gist MichalBrylka 19ae10e62d55ce7cbb2cc9ab21e7e879 Vector1.cs>}}

#### Results
These are the results from my machine:

Category: **Double**
| Method         | Size  | Mean \[μs\] | Error \[μs\] | StdDev \[μs\] | Ratio |
| -------------- | ----- | ----------: | -----------: | ------------: | ----: |
| DoubleBench    | 100   |       8.387 |       0.0545 |        0.0455 |  1.00 |
| Vector1_Double | 100   |       8.462 |       0.0117 |        0.0104 |  1.01 |
| Vector2_Double | 100   |       7.428 |       0.0167 |        0.0148 |  0.89 |
| Span_Double    | 100   |       7.687 |       0.0216 |        0.0191 |  0.92 |
| DoubleBench    | 10000 |     935.063 |       1.4331 |        1.2704 |  1.00 |
| Vector1_Double | 10000 |     935.315 |       2.0107 |        1.6790 |  1.00 |
| Vector2_Double | 10000 |     935.157 |       2.0961 |        1.8581 |  1.00 |
| Span_Double    | 10000 |     934.439 |       2.0086 |        1.7805 |  1.00 |

Category: **Long**
| Method         | Size  | Mean \[μs\] | Error \[μs\] | StdDev \[μs\] | Ratio |
| -------------- | ----- | ----------: | -----------: | ------------: | ----: |
| LongBench      | 100   |       4.712 |       0.0371 |        0.0347 |  1.00 |
| Vector1_Long   | 100   |       5.616 |       0.0367 |        0.0306 |  1.19 |
| Vector2_Long   | 100   |       5.567 |       0.0105 |        0.0093 |  1.18 |
| Span_Long      | 100   |       4.583 |       0.0230 |        0.0192 |  0.97 |
| LongBench      | 10000 |     430.674 |       2.0188 |        1.6858 |  1.00 |
| Vector1_Long   | 10000 |     401.085 |       2.8027 |        2.4845 |  0.93 |
| Vector2_Long   | 10000 |     443.050 |       2.1181 |        1.8776 |  1.03 |
| Span_Long      | 10000 |     393.092 |       2.3554 |        1.9669 |  0.91 |

One can clearly see that memory-wise, they all behave the same - by not allocating anything. Types in benchmark were defined as structs. While it may not be best option for such data structures, it helps here by not obstructing our view with needless allocations). 

Double benchmarks are always ~2 times slower than Long ones but that has nothing to do with generic math itself - floating-point related operations are generally slower on CPUs. 

What also can be observed is that difference in processing speed is negligible. Generic math is not adding much. In case we need to optimize, we can do so by employing pointer arithmetics or (better yet) - [Spans](https://learn.microsoft.com/en-us/archive/msdn-magazine/2018/january/csharp-all-about-span-exploring-a-new-net-mainstay).

One could argue that `DoubleVector`and `LongVector` could also benefit from using additional optimization techniques but we need to repeat them for each and every case. We might probably be more tempted to introduce optimizations when many (generic) types can benefit from these actions.

This graph summarizes in details all benchmarks performed for `System.Long` type for various vector sizes. One can clearly see that differences are almost negligible 
{{< echarts >}}
{
    "title": {
      "text": "Performance of vectors types [μs]",
      "top": "2%",
      "left": "center"
    },
    "tooltip": {
      "trigger": "axis"
    },
    "legend": {
      "data": ["Dedicated vector", "Generic vector" , "Generic vector with pointer arithmetics", "Vector with span backing"],
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
      "data": ["10", "100", "1000", "10000", "100000", "1000000"]
    },
    "yAxis": {
      "type": "value"
    },
    "series": [
      {
        "name": "Dedicated vector",
        "type": "line",        
        "data": [0.5252, 4.6899, 40.6706, 429.6956, 4326.9663, 48113.1239]
      },
      {
        "name": "Generic vector",
        "type": "line",        
        "data": [0.7776, 5.0594, 38.3465, 474.6456, 4693.9954, 48628.9106]
      },
      {
        "name": "Generic vector with pointer arithmetics",
        "type": "line",        
        "data": [0.8456, 5.5831, 47.7041, 471.7119, 4713.6924, 46883.9084]
      },
      {
        "name": "Vector with span backing",
        "type": "line",
        "data": [0.8059, 4.5867, 36.9617, 375.8776, 3788.5032, 43107.3873]
      }
    ]
  }
{{< /echarts >}}

Same data, but restricted only to largest sizes:
{{< echarts >}}
{
    "title": {
      "text": "Performance of vectors types [μs]",
      "top": "2%",
      "left": "center"
    },
    "tooltip": {
      "trigger": "axis"
    },
    "legend": {
      "data": ["Dedicated vector", "Generic vector" , "Generic vector with pointer arithmetics", "Vector with span backing"],
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
      "data": ["10000", "100000", "1000000"]
    },
    "yAxis": {
      "type": "value"
    },
    "series": [
      {
        "name": "Dedicated vector",
        "type": "line",        
        "data": [429.6956, 4326.9663, 48113.1239]
      },
      {
        "name": "Generic vector",
        "type": "line",        
        "data": [474.6456, 4693.9954, 48628.9106]
      },
      {
        "name": "Generic vector with pointer arithmetics",
        "type": "line",        
        "data": [471.7119, 4713.6924, 46883.9084]
      },
      {
        "name": "Vector with span backing",
        "type": "line",
        "data": [375.8776, 3788.5032, 43107.3873]
      }
    ]
  }
{{< /echarts >}}

{{< admonition type=example title="Source code" open=true >}}
Full benchmark and results can be found under this [gist](https://gist.github.com/MichalBrylka/19ae10e62d55ce7cbb2cc9ab21e7e879)
{{< /admonition >}}


## Summary
We've seen how one might go about implementing generic math in their code. This matrix is not complete but quite soon I intend to finish it. It will be distributed via nuget like [my other packages](https://www.nuget.org/profiles/MichalBrylka). 

Are you still not convinced? It seems that Microsoft is already using generic math in their libraries i.e. in many places in LINQ including (but not limited to) [Average](https://github.com/dotnet/runtime/blob/c6f5267686688aeabaa84aeb02efc2b411e7d64b/src/libraries/System.Linq/src/System/Linq/Average.cs#L77) or [Sum](https://github.com/dotnet/runtime/blob/c6f5267686688aeabaa84aeb02efc2b411e7d64b/src/libraries/System.Linq/src/System/Linq/Sum.cs#L63), which replaced some old and seasoned dedicated types copy-and-paste method implementations. If Microsoft is having faith in generic math, there is no reason that shouldn't you. 

## Bonus - physics
This should be treated as a work-in-progress but have a look at my initial proposal on how units can now be defined in C#: [Generic Units](https://gist.github.com/MichalBrylka/c614f567c483bc3a4e4ba5df11007366)

## Sources 
- [Generic Matrix code](https://gist.github.com/MichalBrylka/0b226418e297fbe6d7413e0c812c4d19#file-program-cs)
-  {{< nuget Nemesis.TextParsers >}} was used to provide a nice and performant [equivalent](https://github.com/nemesissoft/Nemesis.TextParsers/blob/3fac52a9b35856ac57e4ae6e6d854a448c7032d8/Nemesis.TextParsers/SpanSplit.cs#L290) to [string.Split](https://learn.microsoft.com/en-us/dotnet/api/system.string.split?view=net-7.0) for `ReadOnlySpan<char>` for parsing purposes