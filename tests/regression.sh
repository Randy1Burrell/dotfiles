#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034,SC2329

set -Eeuo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly REPOSITORY_ROOT
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-regression.XXXXXX")"
trap 'rm -rf -- "${TEST_ROOT}"' EXIT

fail_test() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_equal() {
  local expected="$1" actual="$2" label="$3"
  [[ "${actual}" == "${expected}" ]] || \
    fail_test "${label}: expected [${expected}], got [${actual}]"
}

test_yubikey_login_mapping() (
  export DOTFILES_YUBIKEY_LOGIN_LIBRARY_ONLY=1
  # shellcheck source=../yubikey-login
  source "${REPOSITORY_ROOT}/yubikey-login"

  PAM_AUTHFILE="${TEST_ROOT}/u2f_mappings"
  sudo() { "$@"; }

  local generated result args_file
  generated='test-user:new-handle,new-public-key,es256,+presence+pin'

  result="$(linux_complete_mapping test-user "${generated}")"
  assert_equal "${generated}" "${result}" "first FIDO mapping"

  printf '%s\n' 'test-user:old-handle,old-public-key,es256,+presence+pin' > "${PAM_AUTHFILE}"
  result="$(linux_complete_mapping test-user "${generated}")"
  assert_equal \
    'test-user:old-handle,old-public-key,es256,+presence+pin:new-handle,new-public-key,es256,+presence+pin' \
    "${result}" "additional FIDO mapping"

  printf '%s\n' "${result}" > "${PAM_AUTHFILE}"
  result="$(linux_complete_mapping test-user "${generated}")"
  assert_equal \
    'test-user:old-handle,old-public-key,es256,+presence+pin:new-handle,new-public-key,es256,+presence+pin' \
    "${result}" "duplicate FIDO mapping"

  args_file="${TEST_ROOT}/pamu2fcfg-arguments"
  mock_pamu2fcfg() {
    printf '%s\n' "$*" > "${args_file}"
    printf '%s\n' "${generated}"
  }
  PAMU2FCFG=(mock_pamu2fcfg)
  linux_generate_mapping test-user >/dev/null
  grep -Eq '(^| )-u test-user( |$)' "${args_file}" || \
    fail_test "pamu2fcfg did not receive the username"
  if grep -Eq '(^| )-n( |$)' "${args_file}"; then
    fail_test "pamu2fcfg received incompatible --nouser/-n"
  fi
)

test_secret_rules_and_restore() (
  export HOME="${TEST_ROOT}/home"
  export XDG_STATE_HOME="${TEST_ROOT}/state"
  export DOTFILES_SECRETS_SYNC_LIBRARY_ONLY=1
  mkdir -p "${HOME}/.ssh" "${TEST_ROOT}/private-repository"
  # shellcheck source=../nix/apps/shared/secrets-sync
  source "${REPOSITORY_ROOT}/nix/apps/shared/secrets-sync"

  cat > "${TEST_ROOT}/private-repository/secrets.nix" <<'EOF'
# managed-by: dotfiles-secrets-sync-v2
let recipients = [ ]; in {
  # "id_rsa.age".publicKeys = recipients;
  "authorized_keys.age".publicKeys = recipients;
  "ssh-directory.tar.gz.age".publicKeys = recipients;
}
EOF

  load_enabled_artifacts "${TEST_ROOT}/private-repository"
  artifact_is_enabled authorized_keys.age || fail_test "active rule was ignored"
  artifact_is_enabled ssh-directory.tar.gz.age || fail_test "archive rule was ignored"
  if artifact_is_enabled id_rsa.age; then
    fail_test "commented secret rule was treated as active"
  fi
  if artifact_is_enabled config_external.age; then
    fail_test "removed secret rule was treated as active"
  fi

  printf 'old portable content\n' > "${HOME}/.ssh/portable"
  printf 'destination-only content\n' > "${HOME}/.ssh/destination-only"
  printf 'legacy private key\n' > "${HOME}/.ssh/id_rsa"
  printf 'legacy public key\n' > "${HOME}/.ssh/id_rsa.pub"

  create_ssh_archive "${TEST_ROOT}/portable.tar.gz"
  tar -tzf "${TEST_ROOT}/portable.tar.gz" | grep -Eq '^\./portable$' || \
    fail_test "portable file was omitted from archive"
  if tar -tzf "${TEST_ROOT}/portable.tar.gz" | grep -Eq '^\./id_rsa(\.pub)?$'; then
    fail_test "individually managed secret leaked into portable archive"
  fi

  create_ssh_archive "${TEST_ROOT}/backup.tar.gz" yes
  tar -tzf "${TEST_ROOT}/backup.tar.gz" | grep -Eq '^\./id_rsa$' || \
    fail_test "local safety backup omitted an individual secret"

  mkdir -p "${TEST_ROOT}/restore/nested"
  printf 'new portable content\n' > "${TEST_ROOT}/restore/portable"
  printf 'new nested content\n' > "${TEST_ROOT}/restore/nested/file"
  reconcile_ssh_archive_removals \
    "${TEST_ROOT}/restore" "${TEST_ROOT}/removed"
  restore_ssh_archive "${TEST_ROOT}/restore"

  assert_equal 'new portable content' "$(tr -d '\n' < "${HOME}/.ssh/portable")" \
    "archive replacement"
  [[ -f "${HOME}/.ssh/nested/file" ]] || fail_test "archive did not add nested file"
  [[ ! -e "${HOME}/.ssh/destination-only" ]] || \
    fail_test "destination-only file was not reconciled"
  [[ -f "${TEST_ROOT}/removed/destination-only" ]] || \
    fail_test "destination-only file was not recoverably backed up"
  [[ -f "${HOME}/.ssh/id_rsa" ]] || \
    fail_test "archive reconciliation incorrectly removed an individual secret"

  enabled_artifacts=(authorized_keys.age ssh-directory.tar.gz.age)
  remove_disabled_individual_secrets "${TEST_ROOT}/disabled"
  [[ ! -e "${HOME}/.ssh/id_rsa" && ! -e "${HOME}/.ssh/id_rsa.pub" ]] || \
    fail_test "disabled individual secret remained installed"
  [[ -f "${TEST_ROOT}/disabled/id_rsa" && -f "${TEST_ROOT}/disabled/id_rsa.pub" ]] || \
    fail_test "disabled individual secret was not recoverably backed up"
)

test_yubikey_login_mapping
test_secret_rules_and_restore
printf 'All dotfiles regression tests passed.\n'
