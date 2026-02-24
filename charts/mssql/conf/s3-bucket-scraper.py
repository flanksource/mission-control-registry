#!/usr/bin/env python3
# /// script
# dependencies = ["boto3"]
# ///
import json, re, sys
from urllib.parse import urlparse
import boto3
import os

CONFIG_ID = os.getenv('CONFIG_ID')
REGEX = re.compile(os.getenv('DATABASE_REGEX', r'^(?P<database>[^_]+)_\d*\.bak$'))
S3_PREFIXES = os.getenv('S3_PREFIXES').split(',') if os.getenv('S3_PREFIXES') else []

sys.stderr.write(f'CONFIG_ID: {CONFIG_ID}\n')
sys.stderr.write(f'DATABASE_REGEX: {REGEX.pattern}\n')
sys.stderr.write(f'S3_PREFIXES: {S3_PREFIXES}\n')

s3 = boto3.client('s3')
items = []

def human_size(size):
    if size > 1024 * 1024 * 1024:
            return f'{size / (1024 * 1024 * 1024):.2f} GB'
    return f'{size / (1024 * 1024):.0f} MB'

for s3_uri in S3_PREFIXES:
    parsed = urlparse(s3_uri)
    bucket = parsed.netloc
    prefix = parsed.path.lstrip('/')
    paginator = s3.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get('Contents', []):
            key = obj['Key']
            filename = key.rsplit('/', 1)[-1] if '/' in key else key
            filename = os.path.basename(key)

            if not filename.endswith('.bak'):
                continue
            m = REGEX.match(filename)
            if not m:
                sys.stderr.write(f'Backup does not match regex: {filename}\n')
                continue

            db = m.group('database')
            items.append({
                'id': f'{CONFIG_ID}/{db}/{filename}',
                'name': filename,
                'labels': {'database': db},
                'config': {
                    's3_uri': f's3://{bucket}/{key}',
                    'size': obj['Size'],
                    'size_human': human_size(obj['Size']),
                    'etag': obj['ETag'].strip('"'),
                    'storage_class': obj['StorageClass'],
                    'last_modified': obj['LastModified'].isoformat(),
                },
            })

json.dump({'items': items}, sys.stdout, default=str)
