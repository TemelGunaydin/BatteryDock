#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BatteryDock"
PROJECT_NAME="BatteryDock.xcodeproj"
SCHEME_NAME="BatteryDock"
CONFIGURATION="Release"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_DIR="$ROOT_DIR/.build/DerivedData"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/dmg-staging"
APP_BUNDLE="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"

cd "$ROOT_DIR"

rm -rf "$DIST_DIR"
mkdir -p "$STAGING_DIR"

XCODEBUILD_ARGS=(
  xcodebuild
  -project "$PROJECT_NAME"
  -scheme "$SCHEME_NAME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=macOS"
  -derivedDataPath "$DERIVED_DATA_DIR"
  ONLY_ACTIVE_ARCH=NO
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO
)

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  XCODEBUILD_ARGS+=(
    CODE_SIGN_STYLE=Manual
    "CODE_SIGN_IDENTITY=$DEVELOPER_ID_APPLICATION"
    OTHER_CODE_SIGN_FLAGS=--timestamp
  )
else
  XCODEBUILD_ARGS+=(
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY=-
    DEVELOPMENT_TEAM=
  )
fi

XCODEBUILD_ARGS+=(build)
"${XCODEBUILD_ARGS[@]}"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: app bundle not found at $APP_BUNDLE" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP_BUNDLE/Contents/Info.plist")"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

/usr/bin/ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

codesign --verify --deep --strict --verbose=2 "$STAGING_DIR/$APP_NAME.app"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  codesign --force --sign "$DEVELOPER_ID_APPLICATION" --timestamp "$DMG_PATH"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo "$DMG_PATH"
echo "Version: $VERSION ($BUILD)"
