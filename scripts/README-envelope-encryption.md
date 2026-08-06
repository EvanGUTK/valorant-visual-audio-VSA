Envelope Encryption Example (scripts/envelope_* files)

What is included
- scripts/envelope_crypto_kms.py: KMS client interface, AwsKmsClient, and LocalKmsMock for dev.
- scripts/envelope_crypto_crypto.py: AES-GCM envelope encryption helpers (encrypt_bytes/decrypt_bytes).
- scripts/envelope_example.py: small demo using LocalKmsMock.

How to use
- For local development: run `python scripts/envelope_example.py` (requires `cryptography` in your environment).
- For AWS: create a CMK (see scripts/terraform_kms_aws.tf), ensure the running identity has kms:GenerateDataKey & kms:Decrypt, and use AwsKmsClient(KeyId) in place of LocalKmsMock.

Requirements
- cryptography
- boto3 (if using AwsKmsClient)

Security notes
- LocalKmsMock is for development only — do NOT use in production.
- Ensure plaintext data keys are discarded promptly after use; do not persist them.
- Consider caching decrypted data keys securely for short TTLs only on hot paths.

Next steps to integrate
- Move the scripts/envelope_crypto_* files into a proper package (e.g., lib/envelope_crypto) or infra library.
- Add unit tests for the wrapper and a small integration test using AWS KMS in staging.
- Integrate with object upload/download flows and store the encrypted blob alongside object metadata.
