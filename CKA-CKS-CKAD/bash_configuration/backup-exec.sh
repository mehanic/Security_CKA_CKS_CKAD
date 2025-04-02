#!/bin/bash
DATE=$(date -Iminutes)
CONTAINER=${1:-mysql}
EXEC="docker exec $CONTAINER"
EXEC_SH="$EXEC sh -c"

BACKUP="xtrabackup --backup --target-dir=/var/backups/$DATE --user=root --password=\"\$MYSQL_ROOT_PASSWORD\""
PREPARE="xtrabackup --prepare --target-dir=/var/backups/$DATE --user=root --password=\"\$MYSQL_ROOT_PASSWORD\""

$EXEC mkdir /var/backups/$DATE
$EXEC_SH "$BACKUP"
$EXEC_SH "$PREPARE"
