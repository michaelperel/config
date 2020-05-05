#!/usr/bin/env bash

# Pipeline for onboarding a new tenant.
# First step, read from list of counties (Variable Group variable)
# For each country, check if there exists a keyvault secret
# If not, then create one
# Create new release for the country

set -uexo pipefail

# Source helper functions
. helper.sh

function main() {
    local countries
    local keyvault_name
    local build_number
    countries="${1}"
    keyvault_name="${2}"
    build_number="${3}"

    remove_generated_dirs "releases" "namespaces"


    IFS=',' read -ra con <<< "${countries}"
    for c in "${con[@]}"; do
      get_or_create_primero_secrets "${keyvault_name}" "${c}"
      if [[ ! -f "releases/${c}.yaml" ]]; then
          export COUNTRY="${c}"
          envsubst < "templates/helm-release.yaml" > "releases/${c}.yaml"
          envsubst < "templates/namespace.yaml" > "namespaces/${c}.yaml"
      fi
    done

    local did_commit
    did_commit=0

    local err_if_no_changes
    err_if_no_changes=0

    git_commit_if_changes "pipeline commiting - build number: ${build_number}" "${err_if_no_changes}" did_commit
    if [ $did_commit == 0 ]; then
        echo "did not find changes to commit"
        exit 0
    fi
    echo "changes to be committed:"
    git show
}

main "${COUNTRIES}" "${KEYVAULT_NAME}" "${BUILD_NUMBER}"
