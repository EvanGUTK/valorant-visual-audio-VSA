"""Example usage of the envelope encryption helpers (scripts/envelope_example.py).

This script demonstrates encrypting and decrypting a small payload using the LocalKmsMock
for local development. For AWS usage, instantiate AwsKmsClient with the appropriate KeyId.

Requirements:
- cryptography
- boto3 (only if using AwsKmsClient)

Run locally:
  python scripts/envelope_example.py
"""

from scripts.envelope_crypto_kms import LocalKmsMock, AwsKmsClient
from scripts.envelope_crypto_crypto import encrypt_bytes, decrypt_bytes


def demo_local():
    kms = LocalKmsMock()
    plaintext = b"the quick brown fox jumps over the lazy dog"
    _, blob = encrypt_bytes(kms, 'local-cmk', plaintext)
    print('Encrypted blob (truncated):', blob[:80])
    recovered = decrypt_bytes(kms, blob)
    print('Recovered:', recovered)


if __name__ == '__main__':
    demo_local()