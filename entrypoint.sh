#!/usr/bin/env bash

DEBUG=${DEBUG:-"false"}
SLEEP=${SLEEP:-"0"}

TARGET_FILE=${TARGET_FILE:-""}
TARGET_HOST=${TARGET_HOST:-""}
TARGET_PORT=${TARGET_PORT:-"443"}
RENEWAL_WINDOW=${RENEWAL_WINDOW:-"29"}
PROMETHEUS_DAEMON=${PROMETHEUS_DAEMON:-"false"}
PROMETHEUS_DAEMON_PORT=${PROMETHEUS_DAEMON_PORT:-"9402"}
STACKDRIVER_CLIENT=${STACKDRIVER_CLIENT:-"false"}

SSL_CHECK_COMMAND="./ssl-cert-check"

if [ "${TARGET_FILE}" != "" ]; then
  SSL_CHECK_COMMAND="${SSL_CHECK_COMMAND} -f ${TARGET_FILE} -x ${RENEWAL_WINDOW} -P"
else
  SSL_CHECK_COMMAND="${SSL_CHECK_COMMAND} -s ${TARGET_HOST} -p ${TARGET_PORT} -x ${RENEWAL_WINDOW} -P"
fi

# Do not run as PROMETHEUS_DAEMON in case neither target host or file is provided
if [ "${TARGET_FILE}" == "" ] &&  [ "${TARGET_HOST}" == "" ]; then
  PROMETHEUS_DAEMON="false";
  STACKDRIVER_CLIENT="false";
fi

ssl_check()
{
  echo -ne "$(${SSL_CHECK_COMMAND})"
}

signal_handler()
{
  JOBS="$(jobs -p)"
  if [ "$JOBS" != "" ]; then
      kill $JOBS >/dev/null 2>/dev/null
  fi

  exit 0
}

trap signal_handler SIGINT SIGTERM

sleep "${SLEEP}"

ssl_check_data="$(ssl_check)"

if [ "${STACKDRIVER_CLIENT}" == "true" ]; then

  echo "${ssl_check_data}" > "/tmp/ssl_check_data"

  if [ "${DEBUG}" == "true" ]; then
    echo "${ssl_check_data}"
  fi

  EXIT_STATUS=1
  RETRIES=5
  RETRY_COUNT=1
  while [ "$RETRY_COUNT" -le "$RETRIES" -a "$EXIT_STATUS" != "0"  ]; do
    echo "[Try $RETRY_COUNT of $RETRIES] Posting ssl-cert-check results to Stackdriver..."
    ruby -e '
      require "./stackdriver_client.rb"
      StackdriverClient.process_result("/tmp/ssl_check_data")
    '
    EXIT_STATUS="$?"

    # Sleep only if this is not the last run
    if [ "$RETRY_COUNT" -lt "$RETRIES" -a "$EXIT_STATUS" != "0" ]; then
      sleep 10
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
  done
elif [ "${PROMETHEUS_DAEMON}" == "true" ]; then
  {
    while { echo -en "HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n${ssl_check_data}\n"; } | nc -l -p "${PROMETHEUS_DAEMON_PORT}"; do
      if [ "${DEBUG}" == "true" ]; then
        echo "${ssl_check_data}"
      fi

      ssl_check_data="$(ssl_check)"
    done
  } &

  while true; do
    wait $!
  done
else
  echo "${ssl_check_data}"
fi
