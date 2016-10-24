#!/bin/bash

# Assumption: the group is trusted to read secret information
umask u=rwx,g=rx,o=
mkdir -p /etc/wal-e.d/env

echo "$WALE_AWS_SECRET_ACCESS_KEY" > /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
echo "$WALE_AWS_ACCESS_KEY_ID" > /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
echo "$WALE_S3_PREFIX" > /etc/wal-e.d/env/WALE_S3_PREFIX
echo "$WALE_AWS_REGION" > /etc/wal-e.d/env/AWS_REGION
chown -R root:postgres /etc/wal-e.d

if [ "$POSTGRES_AUTHORITY" = "slave" ]
then
  echo "Authority: Slave - Fetching latest backups";

  if grep -q "/etc/wal-e.d/env" "/var/lib/postgresql/data/recovery.conf"; then
    echo "wal-e already configured in /var/lib/postgresql/data/recovery.conf"
  else
    gosu postgres pg_ctl -D "$PGDATA" -w stop
    # $PGDATA cannot be removed so use temporary dir
    # If you don't stop the server first, you'll waste 5hrs debugging why your WALs aren't pulled
    su - postgres -c "envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-fetch /tmp/pg-data LATEST"
    su - postgres -c "cp -rf /tmp/pg-data/* $PGDATA"
    su - postgres -c "rm -rf /tmp/pg-data"

    # Create recovery.conf
    echo "standby_mode     = 'yes'" >> $PGDATA/recovery.conf
    echo "restore_command  = 'envdir /etc/wal-e.d/env /usr/local/bin/wal-e wal-fetch "%f" "%p"'" >> $PGDATA/recovery.conf
    echo "trigger_file     = '$PGDATA/trigger'" >> $PGDATA/recovery.conf

    chown -R postgres "$PGDATA"

    # Starting server again to satisfy init script
    gosu postgres pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
  fi
else
  echo "Authority: Master - Scheduling WAL backups";

  if grep -q "/etc/wal-e.d/env" "/var/lib/postgresql/data/postgresql.conf"; then
    echo "wal-e already configured in /var/lib/postgresql/data/postgresql.conf"
  else
    echo "wal_level = archive" >> /var/lib/postgresql/data/postgresql.conf
    echo "archive_mode = on" >> /var/lib/postgresql/data/postgresql.conf
    echo "archive_command = 'envdir /etc/wal-e.d/env /usr/local/bin/wal-e wal-push %p'" >> /var/lib/postgresql/data/postgresql.conf
    echo "archive_timeout = 60" >> /var/lib/postgresql/data/postgresql.conf
  fi

  su - postgres -c "crontab -l | { cat; echo \"0 3 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-push /var/lib/postgresql/data\"; } | crontab -"
  su - postgres -c "crontab -l | { cat; echo \"0 4 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e delete --confirm retain 7\"; } | crontab -"
fi
