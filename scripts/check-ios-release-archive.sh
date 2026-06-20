#!/usr/bin/env bash
set -euo pipefail

archive_path=""
expected_build=""
expected_version=""
expected_bundle_id="${ANIMATEAV_IOS_BUNDLE_ID:-com.avalsys.animateav}"
expected_team_id="${ANIMATEAV_APPLE_TEAM_ID:-935PM55U6R}"
expected_keychain_service="${ANIMATEAV_KEYCHAIN_SERVICE:-}"
expected_keychain_access_group="${ANIMATEAV_KEYCHAIN_ACCESS_GROUP:-935PM55U6R.com.avalsys.animateav}"
expected_associated_domain="${ANIMATEAV_ASSOCIATED_DOMAIN:-webcredentials:clerk.avalsys.com}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/check-ios-release-archive.sh --archive <AnimateAV.xcarchive>
    [--expected-build <build>] [--expected-version <version>]

Validates the final Animate AV iOS release archive before App Store Connect upload:
- app version and build;
- bundle identifier;
- Account AV keychain service and access group;
- signing team;
- arm64 archive architecture;
- app dSYM UUID;
- Sentry.framework dSYM UUID.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --archive)
      archive_path="${2:-}"
      shift 2
      ;;
    --expected-build)
      expected_build="${2:-}"
      shift 2
      ;;
    --expected-version)
      expected_version="${2:-}"
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

fail() {
  echo "FAIL $*" >&2
  exit 1
}

plist_print() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true
}

uuid_for() {
  /usr/bin/dwarfdump --uuid "$1" 2>/dev/null | awk '/UUID:/ {print $2; exit}'
}

[ -n "$archive_path" ] || fail "--archive is required."
case "$archive_path" in
  *.xcarchive) ;;
  *) fail "--archive must point to a .xcarchive bundle: $archive_path" ;;
esac
[ -d "$archive_path" ] || fail "archive not found: $archive_path"

archive_path="$(cd "$(dirname "$archive_path")" && pwd)/$(basename "$archive_path")"
app_path="$archive_path/Products/Applications/AnimateAV.app"
app_info="$app_path/Info.plist"
[ -d "$app_path" ] || fail "archive app is missing: $app_path"
[ -f "$app_info" ] || fail "archive app Info.plist is missing: $app_info"

if [ -d "$archive_path/Products/Users" ]; then
  fail "archive contains installed intermediate products under Products/Users; do not override SKIP_INSTALL globally"
fi

version="$(plist_print "$app_info" "CFBundleShortVersionString")"
build="$(plist_print "$app_info" "CFBundleVersion")"
bundle_id="$(plist_print "$app_info" "CFBundleIdentifier")"
url_scheme="$(plist_print "$app_info" "CFBundleURLTypes:0:CFBundleURLSchemes:0")"
keychain_service="$(plist_print "$app_info" "ACCOUNTAV_KEYCHAIN_SERVICE")"
keychain_access_group="$(plist_print "$app_info" "ACCOUNTAV_KEYCHAIN_ACCESS_GROUP")"
archive_team="$(plist_print "$archive_path/Info.plist" "ApplicationProperties:Team")"
architectures="$(plist_print "$archive_path/Info.plist" "ApplicationProperties:Architectures")"
app_binary="$app_path/AnimateAV"
entitlements_file="$(mktemp)"
trap 'rm -f "$entitlements_file"' EXIT

[ "$bundle_id" = "$expected_bundle_id" ] || fail "bundle id must be $expected_bundle_id, got ${bundle_id:-<missing>}"
[ "$url_scheme" = "$bundle_id" ] || fail "callback URL scheme must match bundle id $bundle_id, got ${url_scheme:-<missing>}"
if [ -n "$expected_keychain_service" ]; then
  [ "$keychain_service" = "$expected_keychain_service" ] || fail "ACCOUNTAV_KEYCHAIN_SERVICE must be $expected_keychain_service, got ${keychain_service:-<missing>}"
else
  [ -z "$keychain_service" ] || [ "$keychain_service" = '$(inherited)' ] || fail "ACCOUNTAV_KEYCHAIN_SERVICE must be empty so Clerk uses the bundle id service, got $keychain_service"
fi
[ "$keychain_access_group" = "$expected_keychain_access_group" ] || fail "ACCOUNTAV_KEYCHAIN_ACCESS_GROUP must be $expected_keychain_access_group, got ${keychain_access_group:-<missing>}"
[ -f "$app_binary" ] || fail "app binary is missing: $app_binary"
[ -n "$archive_team" ] || fail "archive metadata is missing ApplicationProperties:Team; Xcode will not export this archive"
[ -n "$architectures" ] || fail "archive metadata is missing ApplicationProperties:Architectures; Xcode will not export this archive"

if [ -n "$expected_build" ]; then
  [ "$build" = "$expected_build" ] || fail "build must be $expected_build, got ${build:-<missing>}"
fi
if [ -n "$expected_version" ]; then
  [ "$version" = "$expected_version" ] || fail "version must be $expected_version, got ${version:-<missing>}"
fi

codesign_team="$(codesign -dv "$app_path" 2>&1 | awk -F= '/TeamIdentifier=/ {print $2; exit}')"
[ "$codesign_team" = "$expected_team_id" ] || fail "codesign team must be $expected_team_id, got ${codesign_team:-<missing>}"
codesign -d --entitlements :- "$app_path" > "$entitlements_file" 2>/dev/null || fail "could not read signed app entitlements"
apple_signin_entitlement="$(plist_print "$entitlements_file" "com.apple.developer.applesignin:0")"
associated_domain_entitlement="$(plist_print "$entitlements_file" "com.apple.developer.associated-domains:0")"
keychain_entitlement="$(plist_print "$entitlements_file" "keychain-access-groups:0")"
[ "$apple_signin_entitlement" = "Default" ] || fail "signed app must include Sign in with Apple Default entitlement"
[ "$associated_domain_entitlement" = "$expected_associated_domain" ] || fail "signed app associated domain must be $expected_associated_domain"
[ "$keychain_entitlement" = "$expected_keychain_access_group" ] || fail "signed app keychain entitlement must be $expected_keychain_access_group"

if [ -n "$archive_team" ]; then
  [ "$archive_team" = "$expected_team_id" ] || fail "archive team must be $expected_team_id, got $archive_team"
fi

if [ -n "$architectures" ]; then
  echo "$architectures" | grep -q "arm64" || fail "archive architectures must include arm64"
else
  lipo -archs "$app_binary" | grep -q "arm64" || fail "app binary architectures must include arm64"
fi

app_dsym="$archive_path/dSYMs/AnimateAV.app.dSYM"
sentry_binary="$app_path/Frameworks/Sentry.framework/Sentry"
sentry_dsym="$archive_path/dSYMs/Sentry.framework.dSYM"

[ -d "$app_dsym" ] || fail "app dSYM is missing: $app_dsym"
[ -f "$sentry_binary" ] || fail "Sentry framework binary is missing: $sentry_binary"
[ -d "$sentry_dsym" ] || fail "Sentry.framework.dSYM is missing: $sentry_dsym"

app_uuid="$(uuid_for "$app_binary")"
app_dsym_uuid="$(uuid_for "$app_dsym")"
sentry_uuid="$(uuid_for "$sentry_binary")"
sentry_dsym_uuid="$(uuid_for "$sentry_dsym")"

[ -n "$app_uuid" ] || fail "could not read app binary UUID"
[ "$app_uuid" = "$app_dsym_uuid" ] || fail "app dSYM UUID $app_dsym_uuid does not match binary UUID $app_uuid"
[ -n "$sentry_uuid" ] || fail "could not read Sentry framework UUID"
[ "$sentry_uuid" = "$sentry_dsym_uuid" ] || fail "Sentry dSYM UUID $sentry_dsym_uuid does not match binary UUID $sentry_uuid"

cat <<REPORT
iOS release archive passed.
  archive: $archive_path
  version: $version
  build: $build
  bundle id: $bundle_id
  Account AV keychain service: $keychain_service
  Account AV keychain access group: $keychain_access_group
  team id: $codesign_team
  app UUID: $app_uuid
  Sentry UUID: $sentry_uuid
REPORT
