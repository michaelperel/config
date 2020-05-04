function get_keyvault_var () { 
  local key_name
  local keyvault_name
  key_name="${1}"
  keyvault_name="${2}"
  local key_val
  key_val="$(az keyvault secret show --name "${key_name}" --vault-name "${keyvault_name}" 2>/dev/null)"
  echo "${key_val}" | jq -r .value
}

function set_keyvault_var () {
  local key_name
  local key_value
  local keyvault_name
  key_name="${1}"
  key_value="${2}"
  keyvault_name="${3}"
  az keyvault secret set --name "${key_name}" --value "${key_value}" --vault-name "${keyvault_name}" > /dev/null 2>&1
}

function ensure_set() {
  for var in "$@"; do
  if [[ -z "${!var}" ]]; then
  echo "Missing postgres value from keyvault: ${var}"
  return 1
  fi
  done
}

