---
title: Certificate converter 
summary: There are times when we need to convert certificate. Tools like OpenSSL are usually the way to go when we control where our certificates are deployed. Sometimes a custom solutions is needed   
publishDate: 2022-12-27
tags: ["cryptography", powershell, scripts]
categories: [programming]
draft: false
author: Michał Bryłka
---

There are times when we need to automatically convert certificate for SSL, signatures and other things. Certificates usually expire every now and then so nobody reasonable likes to sit and wait till it does and only then perform some manual tasks. Tools like OpenSSL are usually the way to go when we control where our certificates are deployed. Sometimes a custom solutions is needed. 

In my case this conversion was about circumventing a subtle bug in [librdkafka](https://github.com/confluentinc/librdkafka) that manifested itself into [Confluent.Kafka](https://github.com/confluentinc/confluent-kafka-dotnet). More on that issue can be read [here](https://github.com/confluentinc/confluent-kafka-dotnet/issues/1708). As of writing this article, this issue is resolved but it didn't find it's way into any release (current release is 1.9.3, newest can be found at {{< nuget Confluent.Kafka >}}). I thus needed to open [P12](https://en.wikipedia.org/wiki/PKCS_12) file format, decrypt it and put it in secure location as [PEM](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) file.  

## Conversion

These are many approaches to solve cryptographic problems in .NET. Many of them pivot around using $3^{rd}$ part library like [Bouncy Castle](https://www.bouncycastle.org/csharp/), but nowadays there finally exists a modern Crypto API in .NET itself - I decided to give it a try. This is a simple code that opens any certificate, takes it's private key (I needed just RSA scheme but other approaches also seem to work) and convert it nicely to PEM format 


``` cs
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

var (input, password, output) = args.Length switch
{
    2 => (args[0], args[1], Path.ChangeExtension(args[0], ".pem")),
    3 => (args[0], args[1], args[2]),
    _ => throw new ArgumentException(
        "Pass either 2 (input, password) or 3 arguments (input, password, output)", nameof(args)),
};

var pem = ConvertToPem(input, password);

File.WriteAllText(output, pem);

static string ConvertToPem(string filename, string password)
{
    using var cert = new X509Certificate2(filename, password, 
        X509KeyStorageFlags.PersistKeySet | X509KeyStorageFlags.Exportable);

    var certPem = new string(PemEncoding.Write("CERTIFICATE", cert.RawData));

    using var certAlgorithm =
        cert.GetRSAPrivateKey() as AsymmetricAlgorithm ??
        cert.GetECDsaPrivateKey() as AsymmetricAlgorithm ??
        cert.GetDSAPrivateKey() as AsymmetricAlgorithm ??
        cert.GetECDiffieHellmanPrivateKey() as AsymmetricAlgorithm ??
        throw new CryptographicException("Unknown certificate algorithm");

    var keyPem = new string(PemEncoding.Write("PRIVATE KEY", certAlgorithm.ExportPkcs8PrivateKey()));
    
    return certPem + Environment.NewLine + keyPem;    
}
```


Similar program needed to run on Windows production machine that obviously will never have .NET SDK installed (and deploying additional binaries is generally tedious in certain environments). So a script equivalent was needed. 

I created the code above in C# as I'm more fluent at C# then I'll ever be at Powershell. This is my attempt to rewrite to Powershell. If it looks to imperative to your taste, I'm open to any suggestions on how this can be improved to appear more like hard-core script that a seasoned admin would not scoff at :grinning:

{{< gist MichalBrylka b242894d6f507f2247e6e7f1d61b1cb8 ConvertCertificate.ps1>}}


## Sources 
- [Certificate converter](https://gist.github.com/MichalBrylka/b242894d6f507f2247e6e7f1d61b1cb8)
