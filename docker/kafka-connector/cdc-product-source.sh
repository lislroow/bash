#!/bin/bash

FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
eval "source \"$FUNCDIR/env.sh\""

opts=$( getopt --options "" --longoptions "save,delete,status" -- $* )
eval set -- $opts


CONNECTOR="cdc-product-source"
PORT="3405"
DATABASE="market-product"
TARGET_TABLE="product"
CONNECTION_URL="jdbc:mariadb://local.mariadb-$DATABASE:$PORT/$DATABASE"
INCREMENTING_COLUMN_NAME="id"

while true; do
  if [ -z $1 ]; then
    break
  fi
  
  case $1 in
    --save)
      curl --location --request PUT $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR'/config' \
      --header 'Content-Type: application/json' \
      --data '{
          "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
          "connection.url": "'$CONNECTION_URL'",
          "connection.user": "root",
          "connection.password": "1",
          "incrementing.column.name": "'$INCREMENTING_COLUMN_NAME'",
          "timestamp.column.name": "modify_date",
          "table.whitelist": "'$TARGET_TABLE'",
          "schema.pattern": "'$TARGET_TABLE'",
          "mode": "timestamp+incrementing",
          "topic.prefix": "cdc_",
          "tasks.max": "3"
      }' | jq -C
      ;;
    --delete)
      curl --location --request DELETE $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR''
      ;;
    --status)
      curl --location $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR'?expand=info&expand=status' | jq -C
      ;;
    --)
      ;;
  esac
  
  shift
done

