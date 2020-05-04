function get_keyvault_var() {
  local key_name
  local keyvault_name
  key_name="${1}"
  keyvault_name="${2}"
  local key_val
  # Will error if the key doesn't exist. Suppressing errors for now.
  key_val="$(az keyvault secret show --name "${key_name}" --vault-name "${keyvault_name}" 2>/dev/null)"
  echo "${key_val}" | jq -r .value
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
  local secrets
  keyvault_name="${1}"
  country_name="${2}"
  secrets=("secret-1" "secret-2")
  for i in "${secrets[@]}"; do
    local secret_value
    secret_value="$(get_keyvault_var "${country_name}-${i}" "${keyvault_name}")"
    if [[ -z "${secret_value}" ]]; then
      secret_value="$(random_string)"
      set_keyvault_var "${country_name}-${i}" "${secret_value}" "${keyvault_name}"
    fi
  done
}

function random_string () {
    set +o pipefail
    LC_ALL=C < /dev/urandom tr -dc '_A-Z-a-z-0-9' | head -c"${1:-32}"
    set -o pipefail
}
