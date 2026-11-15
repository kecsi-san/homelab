#!/usr/bin/env python3
"""Derive the Amazon SES SMTP password from an IAM secret access key.

SES SMTP credentials are not the IAM secret key itself: the password is a signature derived from it
(AWS Signature v4 scheme, documented by AWS). The SMTP user name is the IAM access key id, unchanged.

The secret is read from the AWS_SECRET_ACCESS_KEY environment variable or, when that is unset,
prompted for without echo, so it never lands in the shell history or the process list.

Usage:
    scripts/ses-smtp-password.py [region]        # region defaults to eu-west-1
"""
import base64
import getpass
import hashlib
import hmac
import os
import sys

DATE = "11111111"
SERVICE = "ses"
MESSAGE = "SendRawEmail"
TERMINAL = "aws4_request"
VERSION = 0x04


def _sign(key: bytes, msg: str) -> bytes:
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()


def smtp_password(secret_access_key: str, region: str) -> str:
    signature = _sign(("AWS4" + secret_access_key).encode("utf-8"), DATE)
    for part in (region, SERVICE, TERMINAL, MESSAGE):
        signature = _sign(signature, part)
    return base64.b64encode(bytes([VERSION]) + signature).decode("utf-8")


def main() -> int:
    region = sys.argv[1] if len(sys.argv) > 1 else "eu-west-1"
    secret = os.environ.get("AWS_SECRET_ACCESS_KEY") or getpass.getpass("IAM secret access key: ")
    if not secret:
        print("no secret access key given", file=sys.stderr)
        return 1
    print(smtp_password(secret.strip(), region))
    return 0


if __name__ == "__main__":
    sys.exit(main())
