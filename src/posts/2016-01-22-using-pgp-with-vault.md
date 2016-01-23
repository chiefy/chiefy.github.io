---
layout: post.swig
title: Using PGP Keys With Hashicorp's Vault
date: 2016-01-22 12:00:00
tags:
  - pgp
  - vault
  - hashicorp
  - crypto
  - security
---
Unless you've been living in a DevOps cave, you have probably heard of [Hashicorp](https://hashicorp.com)'s [Vault](https://vaultproject.io). By their own definition:

> Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing. Vault handles leasing, key revocation, key rolling, and auditing. Vault presents a unified API to access multiple backends: HSMs, AWS IAM, SQL databases, raw key/value, and more.

An under-the-radar feature that was recently introduced includes the ability to use [PGP](https://en.wikipedia.org/wiki/Pretty_Good_Privacy) keys to initialize a vault. I am somewhat of a PGP n00b, so I wanted to share how I got this setup working.

<blockquote class="twitter-tweet" data-conversation="none" data-align="center" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/JamieDobson">@JamieDobson</a> Haha, we are using PGP to distribute our internal Vault unseal keys. We are pushing towards zero trust at <a href="https://twitter.com/hashicorp">@hashicorp</a>.</p>&mdash; Armon Dadgar (@armon) <a href="https://twitter.com/armon/status/673279223587442688">December 5, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

In order to get started, you will need some PGP keypairs. For the remainder of this post I will be using [GPG](https://gnupg.org/) which is a FOSS implementation of the PGP standard. If you are on Windows, there is also [gpg4win](https://www.gpg4win.org/). 

## Installing GPG Tools
There are a few options to install tooling: you can install from source, [download a pre-built binary](https://gnupg.org/download/index.html), or use a package managera like `apt` or `brew`. I am running OSX, so we'll use homebrew:

```bash
❯ brew install gpg2
```
Let's test our installation:

```bash
❯ gpg --version
gpg (GnuPG/MacGPG2) 2.0.28
libgcrypt 1.6.3
Copyright (C) 2015 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Home: ~/.gnupg
Supported algorithms:
Pubkey: RSA, RSA, RSA, ELG, DSA
Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,
        CAMELLIA128, CAMELLIA192, CAMELLIA256
Hash: MD5, SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224
Compression: Uncompressed, ZIP, ZLIB, BZIP2
```

## Create a PGP Keypair

```bash
❯ gpg --gen-key
gpg (GnuPG/MacGPG2) 2.0.28; Copyright (C) 2015 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection?
```
Hit `enter` to use the default.

```bash
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048)
```
Use `4096`

```
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
```
We'll use a 2 year expiration.

```
GnuPG needs to construct a user ID to identify your key.

Real name: Hans Gruber
Email address: hans@nakatomi.com
Comment:
You selected this USER-ID:
    "Hans Gruber <hans@nakatomi.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit?
```
Much respect to the recently deceased Alan Rickman, we'll use a fake name and e-mail here for the sake of this demo. Hit `O` to accept. Then enter a passphrase to secure the key.

```
gpg: checking the trustdb
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   3  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 3u
gpg: next trustdb check due at 2018-01-22
pub   4096R/B4C0CE0E 2016-01-23 [expires: 2018-01-22]
      Key fingerprint = D080 6B4A 10F8 EFA1 F200  6805 6BBD F42D B4C0 CE0E
uid       [ultimate] Hans Gruber <hans@nakatomi.com>
sub   4096R/B842B3EB 2016-01-23 [expires: 2018-01-22]
```
Let's list our keys:

```
❯ gpg --list-keys
/Users/chief/.gnupg/pubring.gpg
---------------------------------------
pub   4096R/EC8C9492 2014-04-26
uid       [ unknown] Keybase.io Merkle Signing (v1) <merkle@keybase.io>
sub   4096R/8080955B 2014-04-26
sub   4096R/49DA99D5 2014-04-26 [expires: 2024-04-23]

pub   2048D/00D026C4 2010-08-19 [expires: 2018-08-19]
uid       [ultimate] GPGTools Team <team@gpgtools.org>
uid       [ultimate] GPGMail Project Team (Official OpenPGP Key) <gpgmail-devel@lists.gpgmail.org>
uid       [ultimate] GPGTools Project Team (Official OpenPGP Key) <gpgtools-org@lists.gpgtools.org>
uid       [ultimate] [jpeg image of size 5871]
sub   2048g/DBCBE671 2010-08-19 [expires: 2018-08-19]
sub   4096R/0D9E43F5 2014-04-08 [expires: 2024-01-02]

pub   4096R/621C58AF 2015-06-25 [expires: 2025-06-22]
uid       [ unknown] keybase.io/chief <chief@keybase.io>
sub   4096R/F4BFDCBF 2015-06-25 [expires: 2025-06-22]

pub   4096R/1AEAD978 2016-01-18 [expires: 2020-01-18]
uid       [ultimate] Christopher Najewicz <chief@beefdisciple.com>
uid       [ultimate] [jpeg image of size 6611]
sub   4096R/D4CDB72B 2016-01-18 [expires: 2020-01-18]

pub   4096R/B4C0CE0E 2016-01-23 [expires: 2018-01-22]
uid       [ultimate] Hans Gruber <hans@nakatomi.com>
sub   4096R/B842B3EB 2016-01-23 [expires: 2018-01-22]
```

We now have a PGP keypair for `Hans Gruber`. If you want to read some more on GPG, [read the docs!](https://gnupg.org/gph/en/manual.html).

## Vault Client Setup
For the sake of simplicity, we'll be using the Vault CLI client to interface with the Vault server. Vault also offers an [extensive HTTP API](https://www.vaultproject.io/docs/http/index.html). Again, I am using `brew` here, but you may use whatever package manager you want, or just [download Vault binaries](https://www.vaultproject.io/downloads.html) at the official site.

```bash
❯ brew install vault
```

## Vault Server Setup
For the sake of this article, we'll be using a [docker image I've created](https://quay.io/repository/chiefy/alpine-vault) to run the Vault server.

```bash
❯ docker pull quay.io/chiefy/alpine-vault:0.4.1
```
First, let's generate a Vault configuration for the backend server. A quick note: the below config **is insecure** because it uses the `inmem` storage backend and disables the use of `tls`. **Do not even think about using this setup for anything sensitive**, this is for demo purposes only. If you're interested in getting a secure setup for Vault, please [RTFM](https://www.vaultproject.io/docs/index.html)! Without further ado, here is our `vault.hcl`:

```
backend "inmem" {}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

```
To run the server:

```bash
❯ docker run -d \
--name vault \
--cap-add=IPC_LOCK \
-v $(pwd)/vault.hcl:/etc/vault.hcl \
-p "8200:8200" \
quay.io/chiefy/alpine-vault:0.4.1
```
Make sure the server came up ok:

```bash
docker logs vault
==> Vault server configuration:

         Log Level: info
             Mlock: supported: true, enabled: true
           Backend: inmem
        Listener 1: tcp (addr: "0.0.0.0:8200", tls: "disabled")
           Version: Vault v0.4.1

==> Vault server started! Log data will stream in below:
```
We can check the vault's status:

```bash
❯ curl -XGET http://docker.local:8200/v1/sys/init
{"initialized":false}
```
## Setting `VAULT_ADDR`
In order to use the Vault CLI with our docker container, we have to point it at the correct IP address. If you're using `docker-machine`, you can get the IP by running:

```bash
❯ docker-machine ip <docker-host-name>
```

On my local setup, I use `docker-host` as the host ID. To set `VAULT_ADDR` we can shorten it to:

```bash
❯ export VAULT_ADDR=http://$(docker-machine ip docker-host):8200
```

If you are running Linux, the docker daemon usually listens on `localhost`, so `export VAULT_ADDR=http://localhost:8200`

To make sure everything is setup, let's again try to get the vault's status:

```bash
❯ vault status
Error checking seal status: Error making API request.

URL: GET http://192.168.99.100:8200/v1/sys/seal-status
Code: 400. Errors:

* server is not yet initialized
```

This is good! It means that we connected to Vault's API and it received a `400` because our vault is not yet initialized.

## Exporting The Public Key
In order to initialize and unseal the vault, we will need to export our public key from the PGP keypair we just created. I had a bit of trouble during this step. Hat-tip to [@eedgar](https://github.com/eedgar) on GitHub who posted some tips in [this issue's thread](https://github.com/hashicorp/vault/issues/682#issuecomment-146574727). You will need your key's ID to export it, note the number after `4096R/` in the `gpg` output above when we generated our key. Our key ID is `B4C0CE0E`. Vault will take either a binary keyfile or a base64 encoded keyfile. 

```bash
❯ gpg --export B4C0CE0E | base64 > hans.key
```
I'll also export my personal key:

```bash
❯ gpg --export 1AEAD978 | base64 > chief.key
```


## Initializing Our Vault
Our first step is to initialize the vault. To do this, you must provide some parameters:

```bash
Init Options:

  -key-shares=5           The number of key shares to split the master key
                          into.

  -key-threshold=3        The number of key shares required to reconstruct
                          the master key.

  -pgp-keys               If provided, must be a comma-separated list of
                          files on disk containing binary- or base64-format
                          public PGP keys. The number of files must match
                          'key-shares'. The output unseal keys will encrypted
                          and hex-encoded, in order, with the given public keys.
                          If you want to use them with the 'vault unseal'
                          command, you will need to hex decode and decrypt;
                          this will be the plaintext unseal key.
```
For this example, we are going to use two PHP keys to initialize. Hans and I will be the keybearers. This means that our `-key-shares` should be set to 2 and we'll set `-key-threshold` also to 2.

We'll also need to reference the exported, base64 encoded public keys we created in the previous step.

```bash
❯ vault init -key-shares=2 -key-threshold=2 -pgp-keys=chief.key,hans.key
```

```bash
Key 1: c1c14c03e96c6b2ad4cdb72b011000312d3ba8f34f0df9eaca0a36ad60fe3f5cbc24f88d17b7208b9526b48e67726e708101651d03016fc55f2c57dba535674298c82e786f72ab97398abc3cceeef96117bcd4d7656d97b0ac934d01ff7788b46a6185a03f3d1057368687e1af4e51d48a7778b3d59c45309e069ee8e2bdec91c693cadef1e5ddc6f7e9819d9d2afb0bc028df7f262975d761dc848c716c932c687d9fec98586ca07beb9ad68efedc5bbe5411ac45408ae6d17fc446e844d34f61f0a92bda0c933b3814440f80a55d27caef3a02958c77918c369c87ecc253d4e30f1c61b085ff69fda195549a07a1c4a44a0b49ebd254f513d1c3d6f380eacfdd4c0694ef5046d372b3ad97b0944045fe41bdb519212f64ca799e2e65d9024b2544937a33ce016f45f9f3921b251a98be27641bf6b6171389c8c4ae25ac74c0b79d342c0467dd103af682f2f6bae98e79f5116670c068b470191b97f637589fcedf9a0ca9302c3149a974519b450f6328ef8393af3063d0d93ad27eb829b43796179c3f66669ba5bed11ed85474635b83cc6b417cfaa28a36b06564a9f5e4778c9fc6a58d74822485185fcd145cfcba5d6fc79383b412d0fcecd1d62d238220995f7fda6f0fc92f4536d603490dc9368efec701f7c9969c5e660060a04c5746e404ee55c6c7fc4f71310caa51b604d2e72a21a434d0e15f0d0ac160e4aaa44aa84c5638b4e94622eb928cea542101d2e001e479b8751f5923ec8bebaf4b0968d9bc6de16f7de06ae036e10730e0a4e2f6a058c9f047e6478c54696320bd61516895eff2a260ac568df94df8855d61fe19ee29ff2fb6164540c31592e4685ae292e42da8032f4850d2c9f8136fbe051cb25244cf3b7398e0f5e123efe048e4b62662058ff76e84f4e8e5c7c627900de2f451e3cfe138d700
Key 2: c1c14c0315f6026fb842b3eb0110002d18e4b211e7d5f17c8626d504d5d35ffc2ec96ae299003b5bccfad0aa76ae32bd55a5efc982968c938e4c5cc95c2e97afd80a9241d1b03d47bbf0798f6e630045b0281abd0e1b7881c87a156b0829c4fd467b4f0b41d7b79d2c433c162af0d3c9926a98d40a3d1db332f2f610c3a98e48f28991fe7a99c32f16a9a368b4e87a1c089a6fd136dfdde2c06e68052d730991fcecc02e0642f243e1369c29444bacac88290a96a7335ef0b75d75bac912accb9261424ef18db1b67bd7682a38c3a507d467d04de040d51ad04010bbc42ff704b6188881249d1eb7b86df412591ebe9fa35b46332b38a659a954f22798f6ca8d73266490d90451d446a58404f1479d709c0cb562bbb958bc81f96f757350b1611b019fd26323820490a3a577440d2da78b8b7bd4e4983ec89b2cb8d6dcd75051aa31b5567d743ddd9db3b91d865d36d145a7feba4bbb8261eec8e94095f73089aec25c865ceeb6fd17a85e3612a517d4f06fd62c8c298a85ad01b0a2ade55b80429661c3ac0ac545c96d2cc38e5032f53b6baa7e34a76a8ffecbd8613fbd5f7e6cedca0584ddc8939b2d913e5ce95376edfb1b31fa6593038c90f52c30df5ec2bd97dcf707a9d7aedaedfe8df4cb6ecac68bc3ae8e937fa3781046ffc39551afa3a63f08f6b06ef1d4109f8c2cb2a39d0d8c90f90454098450f9fca72ef820ad0b574ceba9586ec4e741e876b57be0d2e001e4f6236e02f45136761cf9f78d65fd2304e17efde024e0b5e13ecfe068e222fb207ae05ae61ec0e5d13bf49b8ea23b94277a79d65a6187cc344ac5337aa7018c0bd08aefca78f12c613b5d0f76bc33e7481d664216432a3888b4ce7729e910f2289ae25136e056e15b0fe01ee45eb94c7ddca0fe21dc79a4d34ae070a2e2fc189eb1e1bba200
Initial Root Token: f0243ed0-b88f-32b3-a28a-0b5cbf0ac1f2

Vault initialized with 2 keys and a key threshold of 2. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 2 of these keys
to unseal it again.

Vault does not store the master key. Without at least 2 keys,
your Vault will remain permanently sealed.
```

Vault returns two keys, each corresponding to the public keys we supplied the initialization with. To use those keys, you must decrypt them with the private key. Let's decrypt the second one which corresponds to Hans Gruber's public key:

```bash
❯ echo c1c14c0...bba200 | xxd -r -p | gpg -d 
```
This will prompt you to enter your password for Hans' private key.

```bash
You need a passphrase to unlock the secret key for
user: "Hans Gruber <hans@nakatomi.com>"
4096-bit RSA key, ID B842B3EB, created 2016-01-23 (main key ID B4C0CE0E)

gpg: encrypted with 4096-bit RSA key, ID B842B3EB, created 2016-01-23
      "Hans Gruber <hans@nakatomi.com>"
b652edc8ce7e2f8e85f501356fb3fc7649364395ac69a7136b38fb041621afb302
```
The bottom line is our new private vault key! I repeated the process to obtain my own private vault key. Now that we have two keys, we can unseal the vault and start saving some secrets.

## Unseal
Since we set our vault up to require two key-shares to unseal the vault, we'll need both my key and Hans' key to unseal the vault. 

```bash
❯ vault unseal b652edc8ce7e2f8e85f501356fb3fc7649364395ac69a7136b38fb041621afb302
Sealed: true
Key Shares: 2
Key Threshold: 2
Unseal Progress: 1
```
Our `Unseal Progress` is at one, which means we need one more key, which is mine.

```bash
❯ vault unseal bd3a90b4c04c86cd0915d2d2jj32kl2493f2788bc2f39e83223a1887382223ef901
Sealed: false
Key Shares: 2
Key Threshold: 2
Unseal Progress: 0
```
Success! Our vault has been unsealed. Obviously in a real scenario you wouldn't distribute the decrypted unseal keys, but rather give the encrypted base64 text to each user who provided you a public PGP key. 

## Save / Read A Secret
Make sure to use the above provided initial root token to set the `VAULT_TOKEN` environment variable, otherwise your request will not work.

```bash
❯ export VAULT_TOKEN=f1243fd0-b38f-32b3-a28a-0e5cbf0ac1f2
❯ vault write secret/password password=yippie-ki-yay
Success! Data written to: secret/password
❯ vault read secret/password
Key           	Value
lease_duration	2592000
password      	yippie-ki-yay
```

## Conclusion
Hashicorp's Vault is an amazing tool, and this is just one small feature that you could potentially use to create shared secrets with your team.
