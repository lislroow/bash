#!/bin/bash

FUNCDIR=$( cd $( dirname $0 ) && pwd -P )
eval "source \"$FUNCDIR/env.sh\""

opts=$( getopt --options "" --longoptions "customer,product" -- $* )
eval set -- $opts

while true; do
  if [ -z $1 ]; then
    break
  fi
  
  case $1 in
    --customer | --product)
      #curl --location --request GET $CP_KAFKA_CONNECT'/connectors?expand=info&expand=status' | jq -Cr 'to_entries[] | select(.key | startswith("cdc-") and endswith("'${1/--/}'")) | .value'
      curl --location --request GET $CP_KAFKA_CONNECT'/connectors?expand=status' | jq -Cr 'to_entries[] | select(.key | startswith("cdc-") and endswith("'${1/--/}'")) | .value'
      ;;
    --)
      ;;
  esac
  
  shift
done
