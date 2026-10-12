#!/usr/bin/env bash
# Puts the app clone (../ragnarokoffline.app or $SNPC_APP) on the installed
# app's version, builds its stack/ and copies the build outputs that
# `world prepare` takes from the installed runtime. Run after the app updates;
# tests/world.cjs then remakes the test world. See docs/agent/testing.md.
set -eu
. "$(dirname "$0")/common.sh"

[ -d "$APP_CLONE/.git" ] || die "no app clone at $APP_CLONE (set SNPC_APP)"
ver=$(installed_version)
tag="v$ver"
echo "installed app: $ver, clone: $(clone_tag)"

[ -z "$(git -C "$APP_CLONE" status --porcelain)" ] ||
	die "the clone has uncommitted changes, nothing done:
$(git -C "$APP_CLONE" status --short)"

if ! git -C "$APP_CLONE" rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
	retry git -C "$APP_CLONE" fetch -q upstream "+refs/heads/main:refs/remotes/upstream/main" "refs/tags/v*:refs/tags/v*"
	git -C "$APP_CLONE" rev-parse -q --verify "refs/tags/$tag" >/dev/null ||
		die "tag $tag not found in Flux159/ragnarokoffline.app"
fi
if [ "$(git -C "$APP_CLONE" rev-parse HEAD)" != "$(git -C "$APP_CLONE" rev-parse "$tag^{commit}")" ]; then
	git -C "$APP_CLONE" checkout -q "$tag"
	echo "clone checked out $tag"
fi

echo "cargo build in stack/ ..."
(cd "$APP_CLONE/stack" && cargo build -q)

copy_file() { mkdir -p "$(dirname "$APP_CLONE/$1")"; cp -f "$RUNTIME/$1" "$APP_CLONE/$1"; }
copy_dir() { rm -rf "$APP_CLONE/$1"; mkdir -p "$(dirname "$APP_CLONE/$1")"; cp -r "$RUNTIME/$1" "$APP_CLONE/$1"; }
for f in bin/robrowser-remoteclient.exe dist/images.tar.gz; do
	[ -f "$RUNTIME/$f" ] || die "missing in the runtime: $f"
	copy_file "$f"
done
for d in vendor/roBrowserLegacy/dist/Web vendor/ROenglishRE/Translation; do
	[ -d "$RUNTIME/$d" ] || die "missing in the runtime: $d"
	copy_dir "$d"
done
echo "done: clone on $tag, stack built, runtime files copied"
