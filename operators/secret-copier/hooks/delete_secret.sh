#!/usr/bin/env bash

source /hooks/common/functions.sh

hook::config() {
  cat <<EOF
{
  "configVersion": "v1",
  "kubernetes": [
    {
      "apiVersion": "v1",
      "kind": "secret",
      "executeHookOnEvent": [
        "Deleted"
      ],
      "labelSelector": {
        "matchLabels": {
           "secret-copier": "yes"
        }
      },
      "namespace": {
        "nameSelector": {
          "matchNames": [
            "default"
          ]
        }
      }
    }
  ]
}
EOF
}

hook::trigger() {
  # ignore Synchronization for simplicity
  type=$(jq -r '.[0].type' $BINDING_CONTEXT_PATH)
  if [[ $type == "Synchronization" ]] ; then
    echo Got Synchronization event
    exit 0
  fi

  echo "TRIGGER - secret deleted"

  for secret in $(jq -r '.[] | .object.metadata.name' $BINDING_CONTEXT_PATH)
    do
      for namespace in $(kubectl get namespace -o json |
                          jq -r '.items[] |
                            select((.metadata.name == "default" | not) and .status.phase == "Active") | .metadata.name')
      do
        kubectl -n $namespace delete secret $secret
      done
    done
}

common::run_hook "$@"
