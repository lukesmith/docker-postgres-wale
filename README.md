# Postgres docker container with wale

Based on https://github.com/docker-library/postgres with https://github.com/wal-e/wal-e integrated.

Environment variables to pass to the container for WAL-E, all of these must be present or wal-e is not configured.

`AWS_ACCESS_KEY`
`AWS_SECRET_ACCESS_KEY`
`WALE_S3_PREFIX=\"s3://<bucketname>/<path>\"`