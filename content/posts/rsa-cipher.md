---
title: Public key cryptosystems and RSA
summary: In modern times we often need a way to send messages in a covert way, without revealing a key prior to transfer. This can be achieved using systems with public/private keys
date: 2021-06-28
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

RSA is 