# Hashing vs Encryption

**Abstraction level**: concept / pattern
**Category**: security, data transformation

---

## Related Topics

- **Implementations of this**: SHA-256, bcrypt, scrypt (hashing); AES, RSA, ChaCha20 (encryption)
- **Depends on this**: password storage, digital signatures, data integrity checks, certificate validation
- **Works alongside**: salting, key management, authentication patterns, message authentication codes (MACs)
- **Contrast with**: encoding (e.g. Base64 — no secret, purely format transformation; fully reversible by anyone)
- **Temporal neighbors**: understand encoding first; then hashing and encryption; then authentication flows, TLS, and public key infrastructure

---

## What is it

Hashing and encryption are two different ways to transform data. Both take input and produce an output that looks nothing like the original — but they serve different purposes and have fundamentally different properties.

**Hashing** is a one-way transformation: data goes in, a fixed-size fingerprint comes out, and there is no way to reverse it. The same input always produces the same output, but you cannot reconstruct the input from the output.

**Encryption** is a two-way transformation: data is scrambled using a key, and can be unscrambled later by someone who holds the correct key. The intent is confidentiality — hide data from anyone without the key, but allow authorized parties to recover it.

- **Data**: any byte sequence — passwords, messages, files, keys
- **Where it lives**: in transit (network), at rest (database, disk), or in memory during processing
- **Who reads/writes it**: hashes are written once and compared later; encrypted data is written by a sender and decrypted by an authorized receiver
- **How it changes**: hashes are static fingerprints — they do not change unless the input changes; encrypted data can be decrypted and re-encrypted with a different key

---

## What problem does it solve

**The core tension**: some data needs to be verifiable without being stored in the clear. Other data needs to be hidden but recoverable.

**Password storage scenario**:
A site stores user passwords. If it stores them as plain text, a database breach exposes every user's password directly. The site needs to verify "did this user type the right password?" — but it never needs to know what the password actually is.

**Message confidentiality scenario**:
Two parties communicate over an untrusted network. Anyone can intercept packets. The sender needs the receiver to read the message — but nobody else should be able to.

These are two different problems:

| Problem | Need |
|---|---|
| Verify something without storing the original | Hashing |
| Hide data from third parties, allow recovery by authorized party | Encryption |

**What goes wrong when misapplied**:

- Storing encrypted passwords: if the key leaks, every password is exposed at once. Encryption is the wrong tool — you never need to decrypt a password, only compare it.
- Hashing messages meant for a recipient: the recipient cannot recover the original message. Hashing is the wrong tool — it is irreversible.
- Using encoding (Base64) instead of either: encoding has no secret. Anyone can reverse it. It provides zero security.

---

## How does it solve it

### Hashing: verification without recovery

A hash function takes input of any length and returns a fixed-size output (the hash or digest). The same input always produces the same hash. A small change in input produces a completely different hash.

- **One-way**: given the hash, you cannot compute the original input
- **Deterministic**: same input → same output, every time
- **Fixed size**: regardless of input length, output is always the same size (e.g. 256 bits)
- **Collision resistant**: it should be computationally infeasible to find two different inputs that produce the same hash

**Use it for**: verifying that something matches a known value, without storing or transmitting the original.

### Encryption: confidentiality with recovery

Encryption transforms data using a key. The output (ciphertext) is unreadable without the key. Given the correct key, the original data can be recovered exactly.

Two main kinds:
- **Symmetric**: same key encrypts and decrypts. Fast. Requires both parties to share the key securely in advance.
- **Asymmetric**: a public key encrypts; only the paired private key can decrypt. Slower. No need to share a secret in advance.

**Use it for**: hiding data from unauthorized parties while allowing authorized parties to read it.

### Salting (for hashing passwords)

A salt is a random value added to the input before hashing. Two users with the same password produce different hashes. Prevents an attacker from precomputing a table of hash→password mappings (a rainbow table attack).

```
hash("password")          → same result for every user with that password
hash("password" + salt)   → unique result per user, even with identical passwords
```

---

## What if we didn't have it (Alternatives)

### Approach 1 — Store passwords as plain text
```
users table: { email: "alice@x.com", password: "hunter2" }
```
One database breach exposes every user's password directly. No transformation, no protection.

### Approach 2 — Encode passwords (Base64)
```
stored: "aHVudGVyMg==" // Base64 of "hunter2"
```
Looks scrambled but is trivially reversible by anyone. Provides zero security — encoding is not a secret.

### Approach 3 — Encrypt passwords
```
stored: AES_encrypt("hunter2", secretKey)
```
Seems secure until the key leaks — then all passwords are exposed at once. Also, you never need to decrypt a password, so the reversibility of encryption is a liability, not a feature.

### Approach 4 — Roll a custom scrambling function
```js
function scramble(s) { return s.split('').reverse().join('') }
```
Custom transforms are not cryptographically analyzed. Attackers find patterns quickly. Security by obscurity fails as soon as the algorithm is known.

---

## Examples

### Example 1 — Hashing a password (login flow)

```
Registration:
  input:  "hunter2"
  hash:   a94a8fe5c...  ← stored in DB

Login:
  input:  "hunter2"
  hash:   a94a8fe5c...  ← matches stored hash → access granted

  input:  "Hunter2"
  hash:   9f1d2e3b4...  ← does not match → access denied
```

The original password is never stored. Verification works by comparing hashes.

### Example 2 — What a one-character change does to a hash

```
hash("hello")  → 2cf24dba5fb0a...
hash("hellp")  → 7509e5bda0c7...
```

Completely different outputs from nearly identical inputs. This is the avalanche effect — it prevents attackers from guessing inputs by making small tweaks.

### Example 3 — Why salting matters

```
// Without salt:
hash("password123") → 482c811d...
// Every user with "password123" produces the same hash
// Attacker precomputes: 482c811d... → "password123"

// With salt:
hash("password123" + "x7Gq") → 9f2a1e4b...
hash("password123" + "mR3z") → 2d8c7f1a...
// Same password, different hashes — precomputation is useless
```

### Example 4 — Symmetric encryption (message confidentiality)

```
key = "shared-secret"

Sender:   encrypt("meet at noon", key) → "x9Kz2mP..."
Network:  "x9Kz2mP..."  ← interceptor sees only ciphertext
Receiver: decrypt("x9Kz2mP...", key) → "meet at noon"
```

Both parties hold the same key. Anyone without the key sees only noise.

### Example 5 — Asymmetric encryption (key exchange)

```
Bob has:  public key (shared openly) + private key (secret)

Alice:    encrypt("hello Bob", Bob's public key) → ciphertext
Network:  ciphertext
Bob:      decrypt(ciphertext, Bob's private key) → "hello Bob"
```

Alice never needed Bob's private key. Only Bob can decrypt — even Alice cannot after sending.

### Example 6 — Hashing for data integrity (not passwords)

```
File download:
  server publishes: file.zip + hash "3d4f9a..."
  user downloads file.zip
  user computes:    hash(file.zip) → "3d4f9a..." ← matches, file is intact
                    hash(file.zip) → "8b2c1e..." ← mismatch, file was tampered
```

Hash is used here as a fingerprint, not for secrecy. Same principle, different context.

---

## Quickfire (Interview Q&A)

**Q: What is the key difference between hashing and encryption?**
Hashing is one-way — you cannot recover the input. Encryption is two-way — the original data can be recovered with the correct key.

**Q: Why do we hash passwords instead of encrypting them?**
We never need to recover a password — only verify it. Encryption adds unnecessary risk: if the key leaks, all passwords are exposed at once.

**Q: What is a hash collision?**
When two different inputs produce the same hash output. Good hash functions make this computationally infeasible to find deliberately.

**Q: What is a salt, and why is it used?**
A random value added to the input before hashing. It ensures that identical inputs produce different hashes, defeating precomputed lookup table attacks.

**Q: What is the difference between symmetric and asymmetric encryption?**
Symmetric uses the same key to encrypt and decrypt. Asymmetric uses a public key to encrypt and a paired private key to decrypt.

**Q: Can you hash encrypted data?**
Yes. Hashing the ciphertext lets you verify it hasn't been tampered with, without needing to decrypt it first. This is the basis of authenticated encryption.

**Q: What is encoding, and how does it differ from hashing and encryption?**
Encoding is a format transformation with no secret — anyone can reverse it. It provides no security, only a representation change (e.g. Base64).

**Q: Why is a fixed output size useful in hashing?**
It lets you store and compare digests of arbitrary-size inputs in constant space and time, regardless of the original data's length.

**Q: What does "one-way" mean in the context of hashing?**
Given only the hash output, it is computationally infeasible to reconstruct any input that would produce it.

**Q: When would you use a hash for something other than passwords?**
File integrity checks, content-addressed storage (e.g. Git object IDs), deduplication, and cache keys are all common uses.

---

## Key Takeaways

- Hashing is one-way: verify without recovering. Encryption is two-way: hide but allow recovery.
- Use hashing for passwords — you never need to decrypt a password, only compare it.
- Use encryption for data that an authorized party must be able to read later.
- Encoding (Base64) is not security — it has no secret and is trivially reversed.
- Salt your hashes — without it, identical inputs produce identical hashes and precomputed attacks work.
- Symmetric encryption uses one shared key; asymmetric uses a public/private key pair.
- Choosing the wrong tool (encrypting passwords, hashing messages) creates real vulnerabilities.

---

## Vocabulary

### Nouns

**Hash / Digest**
The fixed-size output produced by a hash function. Acts as a fingerprint for the input data.

**Hash function**
A deterministic function that maps any input to a fixed-size output, with no way to reverse the mapping.

**Ciphertext**
The encrypted form of data. Unreadable without the decryption key.

**Plaintext**
The original, unencrypted data — the input to an encryption function, or the output of decryption.

**Key**
A secret value used by an encryption algorithm to control the transformation. Anyone with the key can encrypt or decrypt (symmetric), or only the private key holder can decrypt (asymmetric).

**Salt**
A random value concatenated with input before hashing. Ensures that identical inputs produce different hashes across different records.

**Collision**
Two different inputs that produce the same hash output. Cryptographic hash functions are designed to make finding collisions computationally infeasible.

**Rainbow table**
A precomputed table mapping common inputs to their hashes. Used to reverse unsalted hashes quickly. Salting defeats this attack.

**Symmetric encryption**
An encryption scheme where the same key is used to both encrypt and decrypt. Fast, but requires both parties to securely share the key in advance.

**Asymmetric encryption**
An encryption scheme using a key pair: a public key (shared freely) for encryption, and a private key (kept secret) for decryption.

**Encoding**
A reversible format transformation with no secret — anyone can reverse it. Not a security mechanism. Examples: Base64, URL encoding.

**MAC (Message Authentication Code)**
A short value derived from a message and a shared secret key, used to verify both integrity and authenticity. Combines ideas from hashing and keyed transformations.

### Verbs

**Hash**
To apply a hash function to input data, producing a fixed-size digest.

**Encrypt**
To transform plaintext into ciphertext using a key, making it unreadable to anyone without the key.

**Decrypt**
To reverse encryption using the correct key, recovering the original plaintext.

**Salt**
To prepend or append a random value to input before hashing, ensuring uniqueness of the resulting hash.

**Verify**
To confirm that a given input matches a stored hash by hashing the input and comparing outputs.

### Adjectives

**One-way**
Describes a transformation that cannot be reversed — given the output, the input cannot be recovered. Applies to hash functions.

**Deterministic**
Describes a function that always produces the same output for the same input. Both hashing and encryption are deterministic.

**Collision-resistant**
Describes a hash function where it is computationally infeasible to find two different inputs that produce the same output.

**Symmetric**
Describes an encryption scheme using a single shared key for both encryption and decryption.

**Asymmetric**
Describes an encryption scheme using a key pair — one key encrypts, a different (but mathematically related) key decrypts.

**Reversible**
Describes a transformation from which the original input can be recovered. Encryption is reversible (with the key); hashing is not.
