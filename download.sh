#!/bin/bash
# Copyright (C) 2016  Frédéric Pidancier <GAEL Systems>
# 
# This script aims to perform download of products filtered by Odata.
# run this script as following
# $> USER=user PASSWORD=password  URL='http://dhus_server/odata/v1' sh download.sh [count=10]
# Override system properties:
#  [URL] Url to dhus odata interface.
#  [USER] the dhus username
#  [PASSOWRD] the dhus username password.
#  [FILTER] the Odata expected filter (default: no filter) could be "$filter=startswith(Name,'S2A')" 
# Script parameter is Optional, is ne number of products to be retrieved.
#

# This must be execute with bash!!!
if [ ! "$BASH_VERSION" ] ; then
    exec /bin/bash "$0" "$@"
fi

USER=${USER:-'root'}
PASSWORD=${PASSWORD:-'rootpassword'}
URL=${URL:-'http://dhus_server/odata/v1'}
FILTER=${FILTER:-''}
[ ! -z "${FILTER}" ] && FILTER="${FILTER}&"
PAGE_SIZE=10
SKIP=0
TIMEOUT=600

#COUNT=$(curl -s -k -u $USER:$PASSWORD $URL/Products/\$count) 
COUNT=${1:-10}

COOKIES_FILE=cookies.txt
META_FILE=product.meta

while [ $SKIP -lt $COUNT ]
do
   if [ -f $COOKIES_FILE ]
   then
      COOKIES_ARG="--load-cookies=$COOKIES_FILE"
   else
      COOKIES_ARG="--save-cookies=$COOKIES_FILE"
   fi

   aria2c --check-certificate=false --retry-wait=5 --max-tries=10 --timeout=${TIMEOUT} --http-user=$USER \
      --http-passwd=$PASSWORD -o ${META_FILE} $COOKIES_ARG \
      "${URL}/Products?${FILTER}\$top=$PAGE_SIZE&\$skip=$SKIP&\$format=application/metalink4%2Bxml"
   echo $?

   aria2c -c --max-concurrent-downloads=1 --max-connection-per-server=1 --check-certificate=false \
      --retry-wait=5 --max-tries=10 --timeout=${TIMEOUT} \
      --http-user=$USER --http-passwd=$PASSWORD  $COOKIES_ARG \
      --metalink-file=${META_FILE}
  
   rm -f ${META_FILE}
   SKIP=$(($SKIP+$PAGE_SIZE))
done
rm -f $COOKIES_FILE

