#!/bin/bash

FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
eval "source \"$FUNCDIR/env.sh\""

opts=$( getopt --options "" --longoptions "save,delete,status" -- $* )
eval set -- $opts


CONNECTOR="cdc-product-sink-order"
PORT="3404"
DATABASE="market-order"
TARGET_TABLE="product"
CONNECTION_URL="jdbc:mariadb://local.mariadb-$DATABASE:$PORT/$DATABASE"
PK_FIELDS="id"

while true; do
  if [ -z $1 ]; then
    break
  fi
  
  case $1 in
    --save)
      curl --location --request PUT $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR'/config' \
      --header 'Content-Type: application/json' \
      --data '{
          "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
          "topics": "cdc_'$TARGET_TABLE'",
          "connection.url": "'$CONNECTION_URL'",
          "connection.user": "root",
          "connection.password": "1",
          "table.name.format": "'$DATABASE'.'$TARGET_TABLE'",
          "auto.create": "true",
          "auto.evolve": "true",
          "insert.mode": "insert",
          "pk.fields": "'$PK_FIELDS'",
          "pk.mode": "none",
          "delete.enabled": "false",
          "key.converter": "org.apache.kafka.connect.json.JsonConverter",
          "key.converter.schemas.enable": "true",
          "value.converter": "org.apache.kafka.connect.json.JsonConverter",
          "value.converter.schemas.enable": "true",
          "tasks.max": "1"
      }' | jq -C
      ;;
    --delete)
      curl --location --request DELETE $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR''
      ;;
    --status)
      curl --location --request GET $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR'?expand=info&expand=status' | jq -C
      ;;
    --)
      ;;
  esac
  
  shift
done

