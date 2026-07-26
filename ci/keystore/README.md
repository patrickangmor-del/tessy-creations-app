# CI debug-signing key

`debug.keystore` here is a fixed Android "debug" signing key, checked into
the repo on purpose so every CI build is signed with the same key.

This is not a secret — it's Android's standard debug keystore format
(alias `androiddebugkey`, password `android`), the same default every
Flutter/Android project generates locally. It can't be used to publish to
the Play Store or impersonate anything; it only lets Android install the
app without a warning about an untrusted signer.

It matters because Android refuses to install an update over an existing
app if the signing key changed — it forces an uninstall first, which
wipes the app's local data. Without a fixed key, every GitHub Actions
run (a fresh, disposable machine) would generate a new random debug key,
so every release would look like a "different app" to Android and erase
the on-device database on every update.

The build workflow (`.github/workflows/build-apk.yml`) copies this file to
`~/.android/debug.keystore` before building, which is the path Android's
default debug signing config already looks for — so no other build
configuration changes are needed.
