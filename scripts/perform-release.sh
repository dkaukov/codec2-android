#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 VERSION" >&2
  echo "Example: $0 0.1.1" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
version=$1
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

[[ "$(git branch --show-current)" == main ]] || {
  echo "Releases must be performed from main." >&2
  exit 1
}
[[ -z "$(git status --porcelain)" ]] || {
  echo "Refusing to release from a dirty working tree." >&2
  exit 1
}

git fetch origin main --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || {
  echo "Local main must exactly match origin/main." >&2
  exit 1
}

expected="VERSION_NAME=${version}-SNAPSHOT"
grep -Fxq "$expected" gradle.properties || {
  echo "Expected gradle.properties to contain: $expected" >&2
  exit 1
}

tag="v$version"
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Tag already exists: $tag" >&2
  exit 1
fi

release_commit=$(git rev-parse HEAD)
if [[ -x .private/publish.sh ]]; then
  git tag -a "$tag" -m "codec2-android $version [published-locally]"
  cleanup_local_tag() {
    git tag -d "$tag" >/dev/null 2>&1 || true
  }
  trap cleanup_local_tag EXIT

  .private/publish.sh "$version" --publish
  git push origin "$tag"
  trap - EXIT

  echo "Released io.github.dkaukov:codec2-android:$version locally"
  echo "Pushed $tag; GitHub Actions will record the release without republishing it."
  exit 0
fi

git tag -a "$tag" -m "codec2-android $version"
git push origin "$tag"
echo "No private local publisher found. Waiting for the GitHub release workflow."

api_url="https://api.github.com/repos/dkaukov/codec2-android/actions/runs?event=push&head_sha=$release_commit"
deadline=$((SECONDS + 1800))
status=-
conclusion=-
run_url=-
while (( SECONDS < deadline )); do
  response=$(curl --fail --silent --show-error \
    -H 'Accept: application/vnd.github+json' "$api_url")
  read -r status conclusion run_url <<EOF
$(printf '%s' "$response" | ruby -r json -e '
  runs = JSON.parse(STDIN.read).fetch("workflow_runs", [])
  run = runs.find { |candidate| candidate["name"] == "Release" }
  puts [run&.dig("status"), run&.dig("conclusion"), run&.dig("html_url")].map { |v| v || "-" }.join(" ")
')
EOF
  if [[ "$status" == completed ]]; then
    [[ "$conclusion" == success ]] || {
      echo "Release workflow failed: $run_url" >&2
      exit 1
    }
    echo "Released io.github.dkaukov:codec2-android:$version"
    echo "$run_url"
    exit 0
  fi
  sleep 30
done

echo "Timed out waiting for the release workflow: $run_url" >&2
exit 1
