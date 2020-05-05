#!/usr/bin/env bash

function get_keyvault_var() {
  local key_name
  local keyvault_name
  key_name="${1}"
  keyvault_name="${2}"
  local key_val
  possibilities="$(az keyvault secret list --vault-name "${keyvault_name}" | jq -r --arg key_name "${key_name}" '.[] | select(.name==$key_name)')"
  if [[ -z "${possibilities}" ]]; then
      echo ""
  else
      key_val="$(az keyvault secret show --name "${key_name}" --vault-name "${keyvault_name}" 2>/dev/null)"
      echo "${key_val}" | jq -r .value
  fi
}

function set_keyvault_var() {
  local key_name
  local key_value
  local keyvault_name
  key_name="${1}"
  key_value="${2}"
  keyvault_name="${3}"
  az keyvault secret set --name "${key_name}" --value "${key_value}" --vault-name "${keyvault_name}" >/dev/null 2>&1
}

function ensure_set() {
  for var in "$@"; do
    if [[ -z "${!var}" ]]; then
      echo "Missing postgres value from keyvault: ${var}"
      return 1
    fi
  done
}

function get_or_create_primero_secrets() {
  local keyvault_name
  local country_name
  keyvault_name="${1}"
  country_name="${2}"

  local secrets
  secrets=("secret")
  for i in "${secrets[@]}"; do
    local secret_value
    secret_value="$(get_keyvault_var "${country_name}-${i}" "${keyvault_name}")"
    if [[ -z "${secret_value}" ]]; then
      secret_value="$(random_string)"
      set_keyvault_var "${country_name}-${i}" "${secret_value}" "${keyvault_name}"
    fi
  done
}

# Checks for changes and only commits if there are changes staged. Optionally can be configured to fail if called to commit and no changes are staged.
# First arg - commit message
# Second arg - "should error if there is nothing to commit" flag. Set to 0 if this behavior should be skipped and it will not error when there are no changes.
# Third arg - variable to check if changes were commited or not. Will be set to 1 if changes were made, 0 if not.
function git_commit_if_changes() {

    echo "GIT STATUS"
    git status

    echo "GIT ADD"
    git add -A

    commitSuccess=0
    if [[ $(git status --porcelain) ]] || [ -z "$2" ]; then
        echo "GIT COMMIT"
        git commit -m "$1"
        retVal=$?
        if [[ "$retVal" != "0" ]]; then
            echo "ERROR COMMITING CHANGES -- MAYBE: NO CHANGES STAGED"
            exit $retVal
        fi
        commitSuccess=1
    else
        echo "NOTHING TO COMMIT"
    fi
    echo "commitSuccess=$commitSuccess"
    printf -v $3 "$commitSuccess"
}

function random_string () {
    set +o pipefail
    LC_ALL=C < /dev/urandom tr -dc '_A-Za-z0-9' | head -c"${1:-32}"
    set -o pipefail
}
