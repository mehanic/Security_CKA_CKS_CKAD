#!/bin/bash
DATE=$(date -Iminutes)
mkdir /var/backups/$DATE
xtrabackup --backup --target-dir=/var/backups/$DATE --user=root --password="$MYSQL_ROOT_PASSWORD"
xtrabackup --prepare --target-dir=/var/backups/$DATE --user=root --password="$MYSQL_ROOT_PASSWORD"
