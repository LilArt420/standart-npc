# Shared by tools/*.sh (Git Bash on Windows). Not run on its own.

# The app clone: $SNPC_APP, else ragnarokoffline.app next to the main
# checkout (also right when this runs from a worktree).
main_root=$(cd "$(git -C "$(dirname "$0")" rev-parse --path-format=absolute --git-common-dir)/.." && pwd)
SNPC_ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP_CLONE=${SNPC_APP:-$(dirname "$main_root")/ragnarokoffline.app}
RUNTIME="$APPDATA/Ragnarok Offline/runtime"

die() { echo "error: $*" >&2; exit 1; }

# Network calls sometimes time out here: run once more after a short pause.
retry() { "$@" || { sleep 5; "$@"; }; }

installed_version() {
	[ -f "$RUNTIME/APP_VERSION" ] || die "no $RUNTIME/APP_VERSION (app not installed?)"
	tr -d '\r\n' < "$RUNTIME/APP_VERSION"
}

clone_tag() {
	git -C "$APP_CLONE" describe --tags --exact-match 2>/dev/null ||
		echo "$(git -C "$APP_CLONE" describe --tags 2>/dev/null) (not on a tag)"
}
