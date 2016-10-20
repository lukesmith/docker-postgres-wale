# Postgres docker container with wale

Based on https://github.com/docker-library/postgres with [WAL-E](https://github.com/wal-e/wal-e) installed.

Environment variables to pass to the container for WAL-E, all of these must be present or WAL-E is not configured.

`AWS_ACCESS_KEY_ID`

`AWS_SECRET_ACCESS_KEY`

`WALE_S3_PREFIX=\"s3://<bucketname>/<path>\"`

```
docker run -it \
  --env "WALE_AWS_ACCESS_KEY_ID=****" \
  --env "WALE_AWS_SECRET_ACCESS_KEY=****" \
  --env "WALE_AWS_REGION=eu-west-1" \
  --env "WALE_S3_PREFIX=s3://my-bucket" \
  -v ./data:/var/lib/postgresql/data \
  docker-postgres-wale
```
