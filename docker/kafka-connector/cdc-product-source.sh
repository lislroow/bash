#!/bin/bash

FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
FILENAME=${0##*/} && FILENAME=${FILENAME%.*}
eval "source \"$FUNCDIR/env.sh\""

# usage
function USAGE {
  cat << EOF
- USAGE
Usage: ${0##*/} 
          --prod-save
          --local-save
          --delete
          --status

EOF
  exit 1
}
# //usage

opts=$( getopt --options "h" --longoptions "prod-save,local-save,delete,status,help" -- $* )
eval set -- $opts

CONNECTOR="${FILENAME}"

function save {
  PORT="3405"
  DATABASE="market-product"
  TARGET_TABLE="product"
  CONNECTION_URL="jdbc:mariadb://${PROJECT_NAME}.mariadb-$DATABASE:$PORT/$DATABASE"
  INCREMENTING_COLUMN_NAME="id"
  
  curl --location --request PUT $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR'/config' \
  --header 'Content-Type: application/json' \
  --data '{
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "'$CONNECTION_URL'",
      "connection.user": "root",
      "connection.password": "1",
      "timestamp.column.name": "modify_date",
      "table.whitelist": "'$TARGET_TABLE'",
      "schema.pattern": "'$TARGET_TABLE'",
      "mode": "timestamp",
      "topic.prefix": "cdc_",
      "tasks.max": "3"
  }' | jq -C
}

while true; do
  if [ -z $1 ]; then
    break
  fi
  
  case $1 in
    --prod-save)
      PROJECT_NAME="prod"
      save
      ;;
    --local-save)
      PROJECT_NAME="local"
      save
      ;;
    --delete)
      curl --location --request DELETE $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR''
      ;;
    --status)
      curl --location --request GET $CP_KAFKA_CONNECT'/connectors/'$CONNECTOR'?expand=info&expand=status' | jq -C
      ;;
    --help | -h)
      USAGE
      ;;
  esac
  
  shift
done
