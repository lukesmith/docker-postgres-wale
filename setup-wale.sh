#!/bin/bash

# Assumption: the group is trusted to read secret information
umask u=rwx,g=rx,o=
mkdir -p /etc/wal-e.d/env

echo "$WALE_AWS_SECRET_ACCESS_KEY" > /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
echo "$WALE_AWS_ACCESS_KEY_ID" > /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
echo "$WALE_S3_PREFIX" > /etc/wal-e.d/env/WALE_S3_PREFIX
echo "$WALE_AWS_REGION" > /etc/wal-e.d/env/AWS_REGION
chown -R root:postgres /etc/wal-e.d

# wal-e specific
if grep -q "/etc/wal-e.d/env" "/var/lib/postgresql/data/postgresql.conf"; then
  echo "wal-e already configured in /var/lib/postgresql/data/postgresql.conf"
else
  echo "wal_level = archive" >> /var/lib/postgresql/data/postgresql.conf
  echo "archive_mode = on" >> /var/lib/postgresql/data/postgresql.conf
  echo "archive_command = 'envdir /etc/wal-e.d/env /usr/local/bin/wal-e wal-push %p'" >> /var/lib/postgresql/data/postgresql.conf
  echo "archive_timeout = 60" >> /var/lib/postgresql/data/postgresql.conf
fi

if [ "$POSTGRES_AUTHORITY" = "slave" ]
then
  echo "Authority: Slave - Fetching latest backups";

  su - postgres -c "envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-fetch /tmp/pg-data LATEST"
else
  su - postgres -c "crontab -l | { cat; echo \"0 3 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-push /var/lib/postgresql/data\"; } | crontab -"
  su - postgres -c "crontab -l | { cat; echo \"0 4 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e delete --confirm retain 7\"; } | crontab -"
fi
