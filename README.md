# Postgres docker container with wale

Based on https://github.com/docker-library/postgres with [WAL-E](https://github.com/wal-e/wal-e) installed.

Environment variables to pass to the container for WAL-E, all of these must be present or WAL-E is not configured.

```
WALE_AWS_ACCESS_KEY_ID`
WALE_AWS_SECRET_ACCESS_KEY`
WALE_S3_PREFIX="s3://<bucketname>/<path>"
WALE_AWS_REGION=eu-west-1
```

## Running

The master

```
docker run -it \
  --env "WALE_AWS_ACCESS_KEY_ID=****" \
  --env "WALE_AWS_SECRET_ACCESS_KEY=****" \
  --env "WALE_AWS_REGION=eu-west-1" \
  --env "WALE_S3_PREFIX=s3://my-bucket" \
  --env "POSTGRES_AUTHORITY=master" \
  -v ./data/master:/var/lib/postgresql/data \
  docker-postgres-wale
```

The slave will run in `standby_mode`.

```
docker run -it \
  --env "WALE_AWS_ACCESS_KEY_ID=****" \
  --env "WALE_AWS_SECRET_ACCESS_KEY=****" \
  --env "WALE_AWS_REGION=eu-west-1" \
  --env "WALE_S3_PREFIX=s3://my-bucket" \
  --env "POSTGRES_AUTHORITY=slave" \
  -v ./data/slave:/var/lib/postgresql/data \
  docker-postgres-wale
```

When bringing online `rm ./data/recovery.conf` and start the container with `POSTGRES_AUTHORITY=master`.
