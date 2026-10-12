"""Private S3 bucket for photos, video and audio (spec D5, §7.2).

Files never pass through public URLs: the app uploads with a short-lived presigned PUT
and views with a short-lived presigned GET. On EC2 the IAM role provides credentials.
"""

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from app.config import settings
from app.errors import StorageUnavailable

UPLOAD_URL_SECONDS = 15 * 60
VIEW_URL_SECONDS = 10 * 60

_client = None


def _s3():
    global _client
    if _client is None:
        _client = boto3.client(
            "s3",
            region_name=settings.aws_region,
            config=Config(signature_version="s3v4"),
        )
    return _client


def _unavailable(exc: Exception) -> StorageUnavailable:
    return StorageUnavailable("File storage is not available right now.")


def presign_put(key: str, content_type: str) -> str:
    try:
        return _s3().generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.s3_bucket,
                "Key": key,
                "ContentType": content_type,
            },
            ExpiresIn=UPLOAD_URL_SECONDS,
        )
    except (BotoCoreError, ClientError) as exc:
        raise _unavailable(exc) from exc


def presign_get(key: str) -> str:
    try:
        return _s3().generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket, "Key": key},
            ExpiresIn=VIEW_URL_SECONDS,
        )
    except (BotoCoreError, ClientError) as exc:
        raise _unavailable(exc) from exc


def put_bytes(key: str, data: bytes, content_type: str) -> None:
    try:
        _s3().put_object(
            Bucket=settings.s3_bucket, Key=key, Body=data, ContentType=content_type
        )
    except (BotoCoreError, ClientError) as exc:
        raise _unavailable(exc) from exc


def exists(key: str) -> bool:
    try:
        _s3().head_object(Bucket=settings.s3_bucket, Key=key)
        return True
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") in (
            "404",
            "NoSuchKey",
            "NotFound",
        ):
            return False
        raise _unavailable(exc) from exc
    except BotoCoreError as exc:
        raise _unavailable(exc) from exc


def delete(key: str) -> None:
    try:
        _s3().delete_object(Bucket=settings.s3_bucket, Key=key)
    except (BotoCoreError, ClientError) as exc:
        raise _unavailable(exc) from exc


def list_keys(prefix: str) -> list[str]:
    try:
        response = _s3().list_objects_v2(Bucket=settings.s3_bucket, Prefix=prefix)
        return sorted(obj["Key"] for obj in response.get("Contents", []))
    except (BotoCoreError, ClientError) as exc:
        raise _unavailable(exc) from exc
