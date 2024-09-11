#!/bin/sh

checkNotEmpty() {
	if [ -z "${2}" ]; then
		echo "${1} environment variable is empty"
		exit 1
	fi
}

checkSubshellRc() {
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo $@
		exit ${rc}
	fi
}

parseJson() {
	local attr_val
	attr_val=$(jq -r --arg ATTR_NAME "${1}" '.[$ATTR_NAME]' ${2})
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "failed to parse ${1} out of ${2}, rc: ${rc}"
		exit 2
	fi
	if [ -z ${attr_val} -o "${attr_val}" = "null" ]; then
		echo "empty ${1} in ${2}"
		exit 2
	fi
	echo ${attr_val}
}

checkNotEmpty ENTRA_SERVICE_PRINCIPAL ${ENTRA_SERVICE_PRINCIPAL}
checkNotEmpty AZURE_RESOURCE ${AZURE_RESOURCE}
checkNotEmpty BEARER_TOKEN_FILE ${BEARER_TOKEN_FILE}

if [ ! -r "${ENTRA_SERVICE_PRINCIPAL}" ]; then
	echo "ENTRA_SERVICE_PRINCIPAL ${ENTRA_SERVICE_PRINCIPAL} is not readable"
	exit 1
fi

if [ -f "${BEARER_TOKEN_FILE}" ]; then
	echo "BEARER_TOKEN_FILE ${BEARER_TOKEN_FILE} already exists"
	exit 1
fi

app_id=$(parseJson appId ${ENTRA_SERVICE_PRINCIPAL})
checkSubshellRc ${app_id}
app_passwd=$(parseJson password ${ENTRA_SERVICE_PRINCIPAL})
checkSubshellRc ${app_passwd}
tenant=$(parseJson tenant ${ENTRA_SERVICE_PRINCIPAL})
checkSubshellRc ${tenant}
app_name=$(parseJson displayName ${ENTRA_SERVICE_PRINCIPAL})
checkSubshellRc ${app_name}

token_resp=$(mktemp)
token_url=https://login.microsoftonline.com/${tenant}/oauth2/token
token_print_url='https://login.microsoftonline.com/<tenant>/oauth2/token'
http_status=$(curl -s -o ${token_resp} -w "%{response_code}" -X POST ${token_url} \
	-H 'Content-Type: application/x-www-form-urlencoded' \
	--data-urlencode grant_type=client_credentials \
	--data-urlencode client_id=${app_id} \
	--data-urlencode client_secret=${app_passwd} \
	--data-urlencode resource=${AZURE_RESOURCE})

rc=$?
if [ ${rc} -ne 0 ]; then
	echo "failed to get Azure token from ${token_print_url}"
	echo "curl failed with exit code: ${rc}"
	echo "please check https://everything.curl.dev/cmdline/exitcode.html for the exit code meaning"
	exit 10
fi
if [ "${http_status}" != "200" ]; then
	echo "failed to get Azure token from ${token_print_url}"
	echo "curl failed with HTTP status: ${http_status}"
	echo "please check https://developer.mozilla.org/en-US/docs/Web/HTTP/Status for the HTTP status meaning"
	exit 10
fi

bearer_token=$(parseJson access_token ${token_resp})
checkSubshellRc ${bearer_token}
rm -f ${token_resp}
echo -n ${bearer_token} > ${BEARER_TOKEN_FILE}
rc=$?
if [ ${rc} -ne 0 ]; then
	echo "failed to write token to ${BEARER_TOKEN_FILE}, rc: ${rc}"
	exit 11
fi
echo "got Bearer token for ${app_name}, wrote it to ${BEARER_TOKEN_FILE}"
