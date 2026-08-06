"""KMS client interface and AWS implementation for the example envelope library.

KmsClientInterface methods:
- generate_data_key(cmk_id: str) -> (plaintext_data_key_bytes, encrypted_data_key_bytes)
- decrypt(ciphertext_blob_bytes: bytes) -> plaintext_data_key_bytes

Includes AwsKmsClient (requires boto3) and LocalKmsMock for local testing.
"""
from typing import Tuple


class KmsClientInterface:
    def generate_data_key(self, cmk_id: str) -> Tuple[bytes, bytes]:
        raise NotImplementedError

    def decrypt(self, ciphertext_blob: bytes) -> bytes:
        raise NotImplementedError


# AWS implementation (optional)
try:
    import boto3
except Exception:
    boto3 = None


class AwsKmsClient(KmsClientInterface):
    def __init__(self, region_name: str = None):
        if boto3 is None:
            raise ImportError("boto3 is required for AwsKmsClient — add 'boto3' to requirements.txt")
        self.client = boto3.client('kms', region_name=region_name) if region_name else boto3.client('kms')

    def generate_data_key(self, cmk_id: str):
        resp = self.client.generate_data_key(KeyId=cmk_id, KeySpec='AES_256')
        return resp['Plaintext'], resp['CiphertextBlob']

    def decrypt(self, ciphertext_blob: bytes):
        resp = self.client.decrypt(CiphertextBlob=ciphertext_blob)
        return resp['Plaintext']


# Local mock implementation for development
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


class LocalKmsMock(KmsClientInterface):
    def __init__(self):
        self._master_key = AESGCM.generate_key(bit_length=256)

    def generate_data_key(self, cmk_id: str):
        data_key = AESGCM.generate_key(bit_length=256)
        aesgcm = AESGCM(self._master_key)
        nonce = os.urandom(12)
        ciphertext = aesgcm.encrypt(nonce, data_key, None)
        blob = nonce + ciphertext
        return data_key, blob

    def decrypt(self, ciphertext_blob: bytes):
        nonce = ciphertext_blob[:12]
        ciphertext = ciphertext_blob[12:]
        aesgcm = AESGCM(self._master_key)
        return aesgcm.decrypt(nonce, ciphertext, None)