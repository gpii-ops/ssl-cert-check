#!/usr/bin/env bash

DEBUG=${DEBUG:-"false"}
SLEEP=${SLEEP:-"0"}

TARGET_HOST=${TARGET_HOST:-"google.com"}
TARGET_PORT=${TARGET_PORT:-"443"}
RENEWAL_WINDOW=${RENEWAL_WINDOW:-"29"}
DAEMON=${DAEMON:-"true"}
DAEMON_PORT=${DAEMON_PORT:-"9402"}

ssl_check() {
	echo -ne "$(./ssl-cert-check -s "${TARGET_HOST}" -p "${TARGET_PORT}" -x "${RENEWAL_WINDOW}" -P)"
}

sleep "${SLEEP}"

ssl_check_data="$(ssl_check)"

if [ "${DAEMON}" == "true" ]; then
	while { echo -en "HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n${ssl_check_data}\n"; } | nc -l -p "${DAEMON_PORT}"; do
	  if [ "${DEBUG}" == "true" ]; then
	  	echo "${ssl_check_data}"
	  fi

	  echo

	  ssl_check_data="$(ssl_check)"
	done
else
	echo "${ssl_check_data}"
fi
