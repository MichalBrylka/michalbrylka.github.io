---
title: Public key cryptosystems and RSA
summary: In modern times we often need a way to send messages in a covert way, without revealing a key prior to transfer. This can be achieved using systems with public/private keys
date: 2022-10-28
tags: ["cryptography", legacy]
categories: [math]
draft: true
math: true
author: Michał Bryłka
---

In modern times we often need a way to send messages in a covert way, without revealing a key prior to transfer. It can be achieved using systems with *public*/*private* keys. Let's explore these concepts today. 

## Public key cryptography algorithm
Let's consider a system where there exist 2 different, but mathematically connected keys - a *private* and *public* one. As the name suggest, a public one is *publicly* available whereas private is know only *privately* stored by message sender. Such cryptosystem can be used for encryption/decryption of messages but also for signing/verification of message hashes. This process *can* (but not always) follow (signature part is optional):
{{< mermaid >}}
sequenceDiagram
    participant Alice
    participant Bob
    Alice ->> Bob: Encrypts message using Bob's public key
    Alice ->> Bob: Message hash is signed using Alice's private key
    break message is decrypted using Bob's private key. Signature is verified using Alice's public key
        Bob-->Alice: acknowledgement is sent back
    end
{{< /mermaid >}}


## Knapsack Encryption Algorithm
Knapsack Encryption Algorithm is considered to be first public key cryptosystem. This variation on [knapsack problem](https://en.wikipedia.org/wiki/Knapsack_problem) was proposed in 1978 by Ralph Merkle and Martin Hellman. It uses 2 different knapsack problem parameters. Easy knapsack is used as a private key and hard knapsack is used as a public key. Hard knapsack is subsequently derived from an easy knapsack. 

### Example
Let's consider the following knapsack defined by [superincreasing sequence](https://en.wikipedia.org/wiki/Superincreasing_sequence):
{{< raw >}}
$$ Key_{priv} = [1, 3, 6, 13, 27, 52, 103, 206] $$
{{< /raw >}}
This sequence satisfies {{< raw >}}$ s_{{n+1}}>\sum _{{j=1}}^{n}s_{j}   ${{< /raw >}} for every $ n ≥ 1 $

For this sequence let's perform encryption and decryption:
1. Fix arbitrary numbers  *m* and *n* so that *m* has value larger that sum of all elements of *S* (say 421) and *n* co-prime to *m* (say 69)
{{< admonition tip "Co-prime" true >}}
Two integers are considered co-prime if the only positive integer that divides them is 1
{{< /admonition >}}

2. Multiply all values of *S* by *n* modulo *m* thus obtaining a public key
$$ Key_{pub} = Key_{priv} \times 69\ \mathbf{mod}\ 421\ = [69, 207, 414, 55, 179, 220, 371, 321] $$

3. Calculate [modular multiplicative inverse](https://en.wikipedia.org/wiki/Modular_multiplicative_inverse) $n^{-1}$ so that 
$$ n \times n^{-1} \equiv 1 \pmod{m} $$
so $ n^{-1} = 360$. $ n^{-1} $ as well as $ n $ should only be known to recipient of encrypted message

4. assume message *M* to be "ABC", encoded in standard ASCII that would be 
$$ M = [ 01000001_{(2)}, 01000010_{(2)}, 01000011_{(2)} ] $$

5. Multiply all binary values by corresponding values from public key 
$$ Enc = [207+321, 207+371, 207+371+321] = \newline {\large [528, 578, 899]} $$

6. For decryption we need to multiply each value in encrypted string by $ n^{-1} $ to "cancel out" previous multiplication by $ n $
$$ Dec = [528, 578, 899] \times n^{-1}\ \mathbf{mod}\ m\ = \newline [528, 578, 899] \times 360\ \mathbf{mod}\ 421 = \newline {\large [209, 106, 312] } $$

7. Every element represents cumulative value of a knapsack problem given by our private key. Since our knapsack values are superincreasing, then solution is unequivocal

8. Let's see how can we obtain these values from private key 
{{< raw >}}
$$ 
\begin{array}{|c|c|c|c|c|c|c|c|c|}
 Key_{priv} & 1 & 3 & 6 & 13 & 27 & 52 & 103 & 206 \\ 
   \hline
 209 & 0 & 3 & 0 & 0 & 0 & 0 & 0 & 206 \\
   \hline
 209 & 0 & 1 & 0 & 0 & 0 & 0 & 0 & 1
\end{array}
\\ since: \\
209 = 206 + 3 \\ 
Similarly: \\ 
   106 = 103 + 3 \\
   312 = 206 + 103 + 3 $$
{{< /raw >}}

9. Decrypted vales correspond to our original binary sequence
$$ [ 01000001_{(2)}, 01000010_{(2)}, 01000011_{(2)} ] $$
   
### Practical applications 
While fairly easy to understand, this approach has some downsides. Due to the fact that polynomial time attack was proposed by [Adi Shamir](https://ieeexplore.ieee.org/document/4568386) and another by [Leonard Alderman](https://link.springer.com/chapter/10.1007/978-1-4757-0602-4_29) this cryptosystem is now considered insecure.





## RSA
The RSA encryption method is used to send messages over the internet securely. It is based on the idea that whereas factoring huge numbers is challenging, multiplying large numbers is simple. For instance, verifying that *89* multiplied by *97* equals *8633* is trivial, but determining the (prime) factors of *8633* takes much longer.

Let's start with the beginning. A number $ p $ is considered **prime** if:
{{< raw >}}
$$ p \gt 1 \land k \mid n \Leftrightarrow  k \in \{ 1, n \} $$
{{< /raw >}}

i.e. 7 is prime as it's only divisible by 1 and 7. Conversely, 20 is not a prime as the following factors {1, 2, 4, 5, 10, 20} all divide 20 with no remainder. A number greater than 1 that is not prime is called [a composite number](https://en.wikipedia.org/wiki/Composite_number). 

Why do we keep repeating that both composite and prime numbers must be greater than *1*? We could call *1* the first prime number or even composite number (if we close our eyes slightly :wink:). Main reason is [fundamental theorem of arithmetic](https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic) that was proven in ancient times by Euclid and can be formulated as follows:
> Every integer greater than 1 can be represented **uniquely** as a product of prime numbers, up to the order of the factors

Since uniqueness is very strong characteristic, one must remember about adding "greater than *1*". Should we declare *1* to be prime, we would loose uniqueness as we can multiply numbers by 1 any number of times without changing result. This characteristic will be needed later on.



TODO 
https://simple.wikipedia.org/wiki/RSA_algorithm#:~:text=RSA%20(Rivest%E2%80%93Shamir%E2%80%93Adleman,can%20be%20given%20to%20anyone.
https://brilliant.org/wiki/rsa-encryption/