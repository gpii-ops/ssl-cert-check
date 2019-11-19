#!/usr/bin/env bash

DEBUG=${DEBUG:-"false"}
SLEEP=${SLEEP:-"0"}

TARGET_FILE=${TARGET_FILE:-""}
TARGET_HOST=${TARGET_HOST:-"google.com"}
TARGET_PORT=${TARGET_PORT:-"443"}
RENEWAL_WINDOW=${RENEWAL_WINDOW:-"29"}
DAEMON=${DAEMON:-"true"}
DAEMON_PORT=${DAEMON_PORT:-"9402"}

SSL_CHECK_COMMAND="./ssl-cert-check"

if [ "${TARGET_FILE}" != "" ]; then
  SSL_CHECK_COMMAND="${SSL_CHECK_COMMAND} -f ${TARGET_FILE} -x ${RENEWAL_WINDOW} -P"
else
  SSL_CHECK_COMMAND="${SSL_CHECK_COMMAND} -s ${TARGET_HOST} -p ${TARGET_PORT} -x ${RENEWAL_WINDOW} -P"
fi

ssl_check()
{
  echo -ne "$(${SSL_CHECK_COMMAND})"
}

signal_handler()
{
  kill -s SIGINT $!
  exit 0
}

trap signal_handler SIGINT SIGTERM

sleep "${SLEEP}"

ssl_check_data="$(ssl_check)"

if [ "${DAEMON}" == "true" ]; then
  {
    while { echo -en "HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n${ssl_check_data}\n"; } | nc -l -p "${DAEMON_PORT}"; do
      if [ "${DEBUG}" == "true" ]; then
        echo "${ssl_check_data}"
      fi

      echo

      ssl_check_data="$(ssl_check)"
    done
  } &

  while true; do
    wait $!
  done
else
  echo "${ssl_check_data}"
fi
