#!/bin/bash

RESULT=`docker container inspect -f '{{.State.Status}}' arj_mysql 2>/dev/null`
if [ "$RESULT" != "running" ]; then
  docker-compose up -d arj_mysql_healthy
fi
