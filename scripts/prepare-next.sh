#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 RELEASED_VERSION NEXT_VERSION" >&2
  echo "Example: $0 0.1.1 0.1.2" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage
released_version=$1
next_version=$2
version_pattern='^[0-9]+\.[0-9]+\.[0-9]+$'
[[ "$released_version" =~ $version_pattern && "$next_version" =~ $version_pattern ]] || usage
[[ "$released_version" != "$next_version" ]] || usage

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

[[ "$(git branch --show-current)" == main ]] || {
  echo "The next snapshot must be prepared from main." >&2
  exit 1
}
[[ -z "$(git status --porcelain)" ]] || {
  echo "Refusing to update a dirty working tree." >&2
  exit 1
}

git fetch origin main --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || {
  echo "Local main must exactly match origin/main." >&2
  exit 1
}

tag="v$released_version"
git rev-parse -q --verify "refs/tags/$tag^{}" >/dev/null || {
  echo "Release tag does not exist: $tag" >&2
  exit 1
}
[[ "$(git rev-parse HEAD)" == "$(git rev-parse "refs/tags/$tag^{}")" ]] || {
  echo "$tag does not point to the current main commit." >&2
  exit 1
}

expected="VERSION_NAME=${released_version}-SNAPSHOT"
grep -Fxq "$expected" gradle.properties || {
  echo "Expected gradle.properties to contain: $expected" >&2
  exit 1
}

VERSION_NAME="${next_version}-SNAPSHOT" perl -0pi -e \
  's/^VERSION_NAME=.*$/VERSION_NAME=$ENV{VERSION_NAME}/m' gradle.properties

git add gradle.properties
git commit -m "Prepare for next development iteration"
git push origin main

echo "Advanced main to ${next_version}-SNAPSHOT"
