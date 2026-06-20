#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_name=""
configuration="Debug"
destination_args=(-destination "generic/platform=iOS")
preview_account_api_url="https://api-account-av-preview.avalsys.com"
production_account_api_url="https://api-account-av.avalsys.com"
preview_animate_api_url="https://api-animate-av-preview.avalsys.com"
production_animate_api_url="https://api-animate-av.avalsys.com"

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-ios-runtime-config.sh --env dev|staging|prod [--configuration Debug|Release] [--device <UDID>]

Validates the effective Xcode build settings for Animate AV without printing
secret values. Generate Local.xcconfig for the target environment first.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --env)
      env_name="${2:-}"
      shift 2
      ;;
    --configuration)
      configuration="${2:-}"
      shift 2
      ;;
    --device)
      destination_args=(-destination "id=${2:-}")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$env_name" in
  dev|staging|prod)
    ;;
  *)
    echo "--env must be dev, staging, or prod." >&2
    exit 2
    ;;
esac

settings_file="$(mktemp)"
trap 'rm -f "$settings_file"' EXIT

show_settings_args=(
  -project "$repo_root/apps/ios/AnimateAV.xcodeproj"
  -scheme AnimateAV
  -configuration "$configuration"
)

if [ "${#destination_args[@]}" -gt 0 ]; then
  show_settings_args+=("${destination_args[@]}")
fi

xcodebuild "${show_settings_args[@]}" -showBuildSettings > "$settings_file"

setting() {
  local key="$1"
  awk -F= -v wanted="$key" '
    $1 ~ "^[[:space:]]*" wanted "[[:space:]]*$" {
      value=$2
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "$settings_file"
}

failures=0
fail() {
  printf 'FAIL %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_present() {
  local key="$1"
  local value="$2"
  if [ -z "$value" ] || [ "$value" = '$(inherited)' ]; then
    fail "$key is missing"
  fi
}

product_bundle_identifier="$(setting PRODUCT_BUNDLE_IDENTIFIER)"
config_environment="$(setting ANIMATEAV_CONFIG_ENVIRONMENT)"
account_api_base_url="$(setting ACCOUNTAV_API_BASE_URL)"
animate_api_base_url="$(setting ANIMATEAV_API_BASE_URL)"
convex_url="$(setting ANIMATEAV_CONVEX_URL)"
publishable_key="$(setting ACCOUNTAV_PUBLISHABLE_KEY)"
keychain_service="$(setting ACCOUNTAV_KEYCHAIN_SERVICE)"
keychain_access_group="$(setting ACCOUNTAV_KEYCHAIN_ACCESS_GROUP)"
revenuecat_api_key="$(setting ANIMATEAV_REVENUECAT_PUBLIC_API_KEY)"
revenuecat_offering_id="$(setting ANIMATEAV_REVENUECAT_OFFERING_ID)"
revenuecat_monthly_package_id="$(setting ANIMATEAV_REVENUECAT_MONTHLY_PACKAGE_ID)"
development_team="$(setting DEVELOPMENT_TEAM)"
marketing_version="$(setting MARKETING_VERSION)"
current_project_version="$(setting CURRENT_PROJECT_VERSION)"
support_base_url="$(setting SUPPORTAV_BASE_URL)"
support_email_to="$(setting SUPPORT_EMAIL_TO)"
privacy_url="$(setting ANIMATEAV_PRIVACY_URL)"
terms_url="$(setting ANIMATEAV_TERMS_URL)"
delete_account_url="$(setting ACCOUNTAV_DELETE_ACCOUNT_URL)"
animate_delete_account_url="$(setting ANIMATEAV_DELETE_ACCOUNT_URL)"
open_source_url="$(setting ANIMATEAV_OPEN_SOURCE_URL)"
code_sign_entitlements="$(setting CODE_SIGN_ENTITLEMENTS)"

for item in \
  "PRODUCT_BUNDLE_IDENTIFIER:$product_bundle_identifier" \
  "ANIMATEAV_CONFIG_ENVIRONMENT:$config_environment" \
  "ACCOUNTAV_API_BASE_URL:$account_api_base_url" \
  "ANIMATEAV_API_BASE_URL:$animate_api_base_url" \
  "ANIMATEAV_CONVEX_URL:$convex_url" \
  "ACCOUNTAV_PUBLISHABLE_KEY:$publishable_key" \
  "ACCOUNTAV_KEYCHAIN_ACCESS_GROUP:$keychain_access_group" \
  "ANIMATEAV_REVENUECAT_PUBLIC_API_KEY:$revenuecat_api_key" \
  "ANIMATEAV_REVENUECAT_OFFERING_ID:$revenuecat_offering_id" \
  "ANIMATEAV_REVENUECAT_MONTHLY_PACKAGE_ID:$revenuecat_monthly_package_id" \
  "MARKETING_VERSION:$marketing_version" \
  "CURRENT_PROJECT_VERSION:$current_project_version" \
  "SUPPORTAV_BASE_URL:$support_base_url" \
  "SUPPORT_EMAIL_TO:$support_email_to" \
  "ANIMATEAV_PRIVACY_URL:$privacy_url" \
  "ANIMATEAV_TERMS_URL:$terms_url" \
  "ACCOUNTAV_DELETE_ACCOUNT_URL:$delete_account_url" \
  "ANIMATEAV_DELETE_ACCOUNT_URL:$animate_delete_account_url" \
  "ANIMATEAV_OPEN_SOURCE_URL:$open_source_url" \
  "CODE_SIGN_ENTITLEMENTS:$code_sign_entitlements"; do
  require_present "${item%%:*}" "${item#*:}"
done

[ "$config_environment" = "$env_name" ] || fail "ANIMATEAV_CONFIG_ENVIRONMENT must be $env_name, got ${config_environment:-missing}"
[ "$code_sign_entitlements" = "AnimateAV/App/AnimateAV.entitlements" ] || fail "CODE_SIGN_ENTITLEMENTS must point to AnimateAV/App/AnimateAV.entitlements"
[[ "$convex_url" == https://*.convex.cloud ]] || fail "ANIMATEAV_CONVEX_URL must be a Convex cloud URL"
[[ "$marketing_version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || fail "MARKETING_VERSION must look like 1.0 or 1.0.0"
[[ "$current_project_version" =~ ^[0-9]+$ ]] || fail "CURRENT_PROJECT_VERSION must be an integer"
[[ "$support_base_url" == https://* ]] || fail "SUPPORTAV_BASE_URL must be https"
[[ "$support_email_to" == *"@"* ]] || fail "SUPPORT_EMAIL_TO must look like an email address"
[[ "$privacy_url" == https://* ]] || fail "ANIMATEAV_PRIVACY_URL must be https"
[[ "$terms_url" == https://* ]] || fail "ANIMATEAV_TERMS_URL must be https"
[[ "$delete_account_url" == https://* ]] || fail "ACCOUNTAV_DELETE_ACCOUNT_URL must be https"
[[ "$animate_delete_account_url" == https://* ]] || fail "ANIMATEAV_DELETE_ACCOUNT_URL must be https"
[[ "$open_source_url" == https://* ]] || fail "ANIMATEAV_OPEN_SOURCE_URL must be https"

if [ -n "$revenuecat_api_key" ] && [ "$revenuecat_api_key" != '$(inherited)' ]; then
  [[ "$revenuecat_api_key" == appl_* ]] || fail "ANIMATEAV_REVENUECAT_PUBLIC_API_KEY must be a public Apple SDK key starting with appl_"
  [[ "$revenuecat_api_key" != sk_* ]] || fail "ANIMATEAV_REVENUECAT_PUBLIC_API_KEY must not be a RevenueCat secret key"
fi

[ "$revenuecat_offering_id" != '$(inherited)' ] || fail "ANIMATEAV_REVENUECAT_OFFERING_ID is missing"
[ "$revenuecat_monthly_package_id" != '$(inherited)' ] || fail "ANIMATEAV_REVENUECAT_MONTHLY_PACKAGE_ID is missing"

if [ "$configuration" = "Release" ]; then
  [ "$product_bundle_identifier" = "com.avalsys.animateav" ] || fail "Release bundle must be com.avalsys.animateav, got $product_bundle_identifier"
  [ -z "$keychain_service" ] || [ "$keychain_service" = '$(inherited)' ] || fail "Release ACCOUNTAV_KEYCHAIN_SERVICE must be empty so Clerk uses the bundle id service, got $keychain_service"
  [ "$keychain_access_group" = "935PM55U6R.com.avalsys.animateav" ] || fail "Release ACCOUNTAV_KEYCHAIN_ACCESS_GROUP must be 935PM55U6R.com.avalsys.animateav, got $keychain_access_group"
elif [ "$configuration" = "Debug" ]; then
  [ "$product_bundle_identifier" = "com.avalsys.animateav.dev" ] || fail "Debug bundle must be com.avalsys.animateav.dev, got $product_bundle_identifier"
  [ -z "$keychain_service" ] || [ "$keychain_service" = '$(inherited)' ] || fail "Debug ACCOUNTAV_KEYCHAIN_SERVICE must be empty so Clerk uses the bundle id service, got $keychain_service"
  [ "$keychain_access_group" = "935PM55U6R.com.avalsys.animateav.dev" ] || fail "Debug ACCOUNTAV_KEYCHAIN_ACCESS_GROUP must be 935PM55U6R.com.avalsys.animateav.dev, got $keychain_access_group"
fi

if [ "$env_name" = "prod" ]; then
  [ "$account_api_base_url" = "$production_account_api_url" ] || fail "prod Account API URL mismatch"
  [ "$animate_api_base_url" = "$production_animate_api_url" ] || fail "prod Animate API URL mismatch"
  [[ "$publishable_key" == pk_live_* ]] || fail "prod publishable key must use pk_live"
  if printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
      "$product_bundle_identifier" \
      "$account_api_base_url" \
      "$animate_api_base_url" \
      "$convex_url" \
      "$support_base_url" \
      "$privacy_url" \
      "$terms_url" \
      "$delete_account_url" \
      "$open_source_url" | rg -q 'preview|127\.0\.0\.1|localhost|\.dev'; then
    fail "prod settings contain preview/local/dev values"
  fi
elif [ "$env_name" = "staging" ]; then
  [ "$account_api_base_url" = "$preview_account_api_url" ] || fail "staging Account API URL mismatch"
  [ "$animate_api_base_url" = "$preview_animate_api_url" ] || fail "staging Animate API URL mismatch"
  [[ "$publishable_key" == pk_test_* ]] || fail "staging publishable key must use pk_test"
else
  [ "$account_api_base_url" = "$preview_account_api_url" ] || fail "dev Account API URL must be preview worker"
  [ "$animate_api_base_url" = "$preview_animate_api_url" ] || fail "dev Animate API URL must be preview worker"
  [[ "$publishable_key" == pk_test_* ]] || fail "$env_name publishable key must use pk_test"
fi

redacted_key=""
if [ -n "$publishable_key" ]; then
  redacted_key="${publishable_key:0:8}...${#publishable_key}"
fi

redacted_revenuecat_key=""
if [ -n "$revenuecat_api_key" ]; then
  redacted_revenuecat_key="${revenuecat_api_key:0:8}...${#revenuecat_api_key}"
fi

cat <<EOF
Animate AV iOS runtime config ($env_name)
  configuration: $configuration
  product bundle: $product_bundle_identifier
  marketing version: $marketing_version
  build number: $current_project_version
  config environment: $config_environment
  development team: ${development_team:-unknown}
  Account AV API: $account_api_base_url
  Animate AV API: $animate_api_base_url
  Account AV keychain service: $keychain_service
  Account AV keychain access group: $keychain_access_group
  Convex URL: $convex_url
  support URL: $support_base_url
  support email: $support_email_to
  privacy URL: $privacy_url
  terms URL: $terms_url
  delete account URL: $delete_account_url
  open source URL: $open_source_url
  code sign entitlements: $code_sign_entitlements
  Account AV redirect URI: $product_bundle_identifier://callback
  publishable key: $redacted_key
  RevenueCat key: $redacted_revenuecat_key
  RevenueCat offering: $revenuecat_offering_id
  RevenueCat monthly package: $revenuecat_monthly_package_id
EOF

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo "Runtime config check passed."
