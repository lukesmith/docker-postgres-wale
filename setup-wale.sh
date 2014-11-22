#!/bin/bash

if [ "$AWS_ACCESS_KEY" = "" ]
then
    echo "AWS_ACCESS_KEY does not exist"
else
    if [ "$AWS_SECRET_ACCESS_KEY" = "" ]
    then
        echo "AWS_SECRET_ACCESS_KEY does not exist"
    else
        if [ "$WALE_S3_PREFIX" = "" ]
        then
            echo "WALE_S3_PREFIX does not exist"
        else
            # Assumption: the group is trusted to read secret information
            umask u=rwx,g=rx,o=
            mkdir -p /etc/wal-e.d/env

            echo "$AWS_SECRET_ACCESS_KEY" > /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
            echo "$AWS_ACCESS_KEY" > /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
            echo "$WALE_S3_PREFIX" > /etc/wal-e.d/env/WALE_S3_PREFIX
            chown -R root:postgres /etc/wal-e.d

            # wal-e specific
            echo "wal_level = archive" >> /var/lib/postgresql/data/postgresql.conf
            echo "archive_mode = on" >> /var/lib/postgresql/data/postgresql.conf
            echo "archive_command = 'envdir /etc/wal-e.d/env /usr/local/bin/wal-e wal-push %p'" >> /var/lib/postgresql/data/postgresql.conf
            echo "archive_timeout = 60" >> /var/lib/postgresql/data/postgresql.conf

            su - postgres -c "/usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-push /var/lib/postgresql/data"
            su - postgres -c "crontab -l | { cat; echo \"0 3 * * * /usr/bin/envdir /etc/wal-e.d/env /usr/local/bin/wal-e backup-push /var/lib/postgresql/data\"; } | crontab -"
        fi
    fi
fi