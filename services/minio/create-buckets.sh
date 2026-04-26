#!/bin/sh
set -e

# Wait for MinIO to be ready
echo "Waiting for MinIO..."
until mc alias set myminio "http://$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"; do
  echo "MinIO alias set failed (or unnreachable) - sleeping"
  sleep 2
done

until mc admin info myminio > /dev/null 2>&1; do
  echo "MinIO is unavailable - sleeping"
  sleep 2
done

echo "MinIO is up - checking buckets: $MINIO_BUCKETS"

# Create buckets
# We replace comma with space to loop
for BUCKET in $(echo $MINIO_BUCKETS | tr ',' ' '); do
  if ! mc ls "myminio/$BUCKET" > /dev/null 2>&1; then
    echo "Creating bucket: $BUCKET"
    mc mb "myminio/$BUCKET"
  else
    echo "Bucket '$BUCKET' already exists."
  fi
done

echo "MinIO bucket initialization complete."