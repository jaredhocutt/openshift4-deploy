#!/usr/bin/env bash

help () {
  echo "ERROR: This command needs a num_workers argument."
  echo "For example: $(basename $0) 3"
  echo "will check that 3 worker nodes are in Ready state"
  exit 1;
}

if [ $# -ne 1 ]; then
    help
fi

TIMEOUT=$(date --date='now + 300 seconds' +%s)

while [ $(date +%s) -lt $TIMEOUT ]; do
  READY_COUNT=$(oc get nodes \
	          --selector='node-role.kubernetes.io/worker=' \
		  --output=custom-columns='READY:status.conditions[?(@.type=="Ready")].status' \
		  --no-headers \
		  | grep --count "True")
  if [ $READY_COUNT -ge $1 ]; then
    echo "SUCCESS at $(date): Found $READY_COUNT workers in Ready state" && exit 0
  else
    echo "PROGRESSING at $(date): Found $READY_COUNT of $1 workers in Ready state."
    oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' \
      | xargs --no-run-if-empty oc adm certificate approve
  fi
  sleep 5
done

echo "FAIL: 300 seconds have elapsed..." && exit 1
