"""Envelope encryption helpers (example implementation placed in scripts/).

Performs AES-GCM encryption/decryption and coordinates with a KMS client
that implements generate_data_key(cmk_id) -> (plaintext_key_bytes, ciphertext_blob_bytes)
and decrypt(ciphertext_blob_bytes) -> plaintext_key_bytes.

Encrypted blob format (JSON, UTF-8 bytes):
{
  "version": 1,
  "key_ciphertext": <base64>,
  "nonce": <base64>,
  "ciphertext": <base64>
}
"""

import base64
import json
from typing import Tuple

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os


def _b64(b: bytes) -> str:
    return base64.b64encode(b).decode('utf-8')


def _ub64(s: str) -> bytes:
    return base64.b64decode(s.encode('utf-8'))


def encrypt_bytes(kms_client, cmk_id: str, plaintext: bytes) -> Tuple[bytes, bytes]:
    """Generate a data key from KMS, encrypt plaintext with AES-GCM and return (plaintext_key, encrypted_blob).

    Returns:
      (plaintext_data_key_bytes, encrypted_blob_bytes)
    """
    plaintext_data_key, encrypted_data_key = kms_client.generate_data_key(cmk_id)

    aesgcm = AESGCM(plaintext_data_key)
    nonce = os.urandom(12)
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)

    blob = {
        "version": 1,
        "key_ciphertext": _b64(encrypted_data_key),
        "nonce": _b64(nonce),
        "ciphertext": _b64(ciphertext),
    }

    blob_bytes = json.dumps(blob).encode('utf-8')
    return plaintext_data_key, blob_bytes


def decrypt_bytes(kms_client, encrypted_blob_bytes: bytes) -> bytes:
    blob = json.loads(encrypted_blob_bytes.decode('utf-8'))
    version = blob.get('version')
    if version != 1:
        raise ValueError(f"Unsupported envelope format version: {version}")

    encrypted_data_key = _ub64(blob['key_ciphertext'])
    nonce = _ub64(blob['nonce'])
    ciphertext = _ub64(blob['ciphertext'])

    plaintext_data_key = kms_client.decrypt(encrypted_data_key)

    aesgcm = AESGCM(plaintext_data_key)
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return plaintext