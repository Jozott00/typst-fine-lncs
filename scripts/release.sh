#!/usr/bin/env bash
#
# Pre-flight checks + Typst Universe publication for fine-lncs.
#
# VERSION is the source of truth. This script verifies that every other
# version reference in the repo matches VERSION, that VERSION is a bump
# over the most recent git tag, and that CI passes — then hands off to
# `utpm prj publish`.
#
# Pass --dry-run to run the checks without publishing.

set -euo pipefail

DRY_RUN=0
if [[ ${1:-} == "--dry-run" ]]; then
  DRY_RUN=1
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fail() {
  echo "release: $*" >&2
  exit 1
}

info() {
  echo "release: $*"
}

github_api() {
  curl -fsS \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $UTPM_GITHUB_TOKEN" \
    "${@}"
}

json_field() {
  local field=$1
  sed -n "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1
}

# --- Load optional local environment ------------------------------------
#
# Allows release credentials such as UTPM_GITHUB_TOKEN to live in a
# repo-local .env file without hardcoding them in the script.

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

# --- Load VERSION --------------------------------------------------------

[[ -f VERSION ]] || fail "VERSION file not found at repo root"
version=$(tr -d '[:space:]' < VERSION)
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail "VERSION ($version) is not a valid X.Y.Z semver"

info "target version: $version"

# --- Compare to latest git tag ------------------------------------------
#
# Fetch tags from origin so releases that exist on GitHub but haven't been
# pulled locally are still seen. The GitHub tag/release flow is independent
# of Universe publication, so origin is the authoritative source.

info "fetching tags from origin"
git fetch --quiet --tags origin \
  || fail "failed to fetch tags from origin (network? remote name?)"

prev_tag=$(git tag -l 'v*' --sort=-v:refname | head -n1)
if [[ -z $prev_tag ]]; then
  info "no previous release tag — treating as first release"
else
  prev=${prev_tag#v}
  if [[ $prev == "$version" ]]; then
    fail "VERSION matches the latest tag ($prev_tag) — bump VERSION before releasing"
  fi
  highest=$(printf '%s\n%s\n' "$prev" "$version" | sort -V | tail -n1)
  [[ $highest == "$version" ]] \
    || fail "VERSION ($version) is not greater than the latest tag ($prev_tag)"
  info "previous release: $prev_tag"
fi

# --- typst.toml ----------------------------------------------------------

toml_version=$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)
[[ $toml_version == "$version" ]] \
  || fail "typst.toml version ($toml_version) does not match VERSION ($version)"

package_name=$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' typst.toml)
[[ -n $package_name ]] \
  || fail "typst.toml package name is missing"

# --- Scan repo for stale version references -----------------------------
#
# Any occurrence of `fine-lncs:X.Y.Z` must match the target version. This
# covers README examples and the template's own import line.

stale=$(grep -RnE 'fine-lncs:[0-9]+\.[0-9]+\.[0-9]+' \
          --include='*.md' --include='*.typ' --include='*.toml' . \
        | grep -v "fine-lncs:$version" || true)
if [[ -n $stale ]]; then
  echo "release: stale version references found (must match $version):" >&2
  echo "$stale" >&2
  exit 1
fi

# --- Working tree must be clean -----------------------------------------

if [[ -n $(git status --porcelain) ]]; then
  echo "release: working tree is not clean:" >&2
  git status --short >&2
  exit 1
fi

# --- Must be on the matching release branch -----------------------------

branch=$(git rev-parse --abbrev-ref HEAD)
expected_branch="release/$version"
[[ $branch == "$expected_branch" ]] \
  || fail "not on $expected_branch (currently on $branch)"

# --- Run full CI locally ------------------------------------------------

info "running format + test checks (just ci)"
just ci

# --- Publish ------------------------------------------------------------

if (( DRY_RUN )); then
  info "dry run — skipping publication"
  info "all pre-flight checks passed for $version"
  exit 0
fi

command -v utpm >/dev/null 2>&1 \
  || fail "utpm is not installed or not on PATH"

utpm prj publish --help >/dev/null 2>&1 \
  || fail "installed utpm does not support 'prj publish'"

[[ -n ${UTPM_GITHUB_TOKEN:-} ]] \
  || fail "UTPM_GITHUB_TOKEN is not set"

# utpm 0.3.0 assumes its git-packages workdir already exists before publish.
# It can also leave behind a non-git directory after a failed publish, which
# then causes later `git add/commit/push` steps to fail with "not a git
# repository". Bootstrap the Universe packages checkout ourselves so `utpm`
# always sees a valid repo. Recreate that checkout as a sparse worktree for
# just this package so we never need to walk an old full typst/packages tree.
if [[ -n ${UTPM_DATA_DIR:-} ]]; then
  utpm_data_dir=$UTPM_DATA_DIR
elif [[ ${OSTYPE:-} == darwin* ]]; then
  utpm_data_dir="$HOME/Library/Application Support/utpm"
else
  utpm_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/utpm"
fi

utpm_git_packages_dir="$utpm_data_dir/git-packages"
utpm_packages_repo=${UTPM_PACKAGES_REPO:-https://github.com/typst/packages.git}
utpm_packages_upstream=${UTPM_PACKAGES_UPSTREAM:-typst/packages}
utpm_packages_namespace=${UTPM_PACKAGES_NAMESPACE:-preview}
utpm_packages_fork_owner=${UTPM_PACKAGES_FORK_OWNER:-}
utpm_packages_push_url=${UTPM_PACKAGES_PUSH_URL:-}
UTPM_GITHUB_API=${UTPM_GITHUB_API:-https://api.github.com}
utpm_sparse_checkout_path="packages/${utpm_packages_namespace}/${package_name}"
utpm_pr_title=${UTPM_PR_TITLE:-"${package_name}:${version}"}
utpm_pr_body=${UTPM_PR_BODY:-"I am submitting\\n- [ ] a new package\\n- [x] an update for a package\\n\\nRelease of ${package_name} ${version}."}

mkdir -p "$utpm_data_dir" \
  || fail "failed to create utpm data dir at $utpm_data_dir"

configure_utpm_sparse_checkout() {
  git -C "$utpm_git_packages_dir" sparse-checkout init --cone >/dev/null \
    || fail "failed to initialize sparse-checkout for utpm workdir"
  git -C "$utpm_git_packages_dir" sparse-checkout set "$utpm_sparse_checkout_path" >/dev/null \
    || fail "failed to configure sparse-checkout for $utpm_sparse_checkout_path"
}

prepare_utpm_main_branch() {
  git -C "$utpm_git_packages_dir" checkout --quiet -B main origin/main \
    || fail "failed to check out origin/main in utpm workdir"
  git -C "$utpm_git_packages_dir" config branch.main.remote origin \
    || fail "failed to set remote for utpm main branch"
  git -C "$utpm_git_packages_dir" config branch.main.merge refs/heads/main \
    || fail "failed to set merge ref for utpm main branch"
  configure_utpm_sparse_checkout
}

sync_utpm_fork_main_if_needed() {
  if ! git ls-remote --exit-code --heads "$utpm_packages_push_url" main >/dev/null 2>&1; then
    return
  fi

  git -C "$utpm_git_packages_dir" fetch --quiet "$utpm_packages_push_url" \
    "refs/heads/main:refs/remotes/fork/main" \
    || fail "failed to fetch fork main branch"

  if git -C "$utpm_git_packages_dir" merge-base --is-ancestor refs/remotes/fork/main origin/main; then
    return
  fi

  info "syncing fork main back to upstream main for utpm"
  git -C "$utpm_git_packages_dir" push --quiet --force "$utpm_packages_push_url" origin/main:main \
    || fail "failed to sync fork main back to upstream main"
}

create_or_reuse_utpm_pull_request() {
  local existing_pr_json existing_pr_url pr_payload pr_json pr_url
  existing_pr_json=$(github_api \
    "$UTPM_GITHUB_API/repos/${utpm_packages_upstream}/pulls?state=open&head=${utpm_packages_fork_owner}:main&base=main") \
    || fail "failed to query existing pull requests for ${utpm_packages_fork_owner}:main"
  existing_pr_url=$(printf '%s' "$existing_pr_json" | tr -d '\n' | json_field html_url)

  if [[ -n $existing_pr_url ]]; then
    info "pull request already exists: $existing_pr_url"
    return
  fi

  pr_payload=$(printf \
    '{"title":"%s","head":"%s:main","base":"main","body":"%s"}' \
    "$utpm_pr_title" \
    "$utpm_packages_fork_owner" \
    "$utpm_pr_body")

  pr_json=$(github_api -X POST "$UTPM_GITHUB_API/repos/${utpm_packages_upstream}/pulls" -d "$pr_payload") \
    || fail "failed to create pull request for ${utpm_packages_fork_owner}:main"
  pr_url=$(printf '%s' "$pr_json" | tr -d '\n' | json_field html_url)
  [[ -n $pr_url ]] || fail "failed to extract pull request URL from GitHub response"
  info "created pull request: $pr_url"
}

if [[ -e $utpm_git_packages_dir ]]; then
  backup_dir="${utpm_git_packages_dir}.stale.$(date +%Y%m%d%H%M%S)"
  info "archiving existing utpm workdir to $backup_dir"
  mv "$utpm_git_packages_dir" "$backup_dir" \
    || fail "failed to move utpm workdir to $backup_dir"
fi

if ! git -C "$utpm_git_packages_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  info "bootstrapping sparse Typst Universe repo into $utpm_git_packages_dir"
  git clone --quiet --depth=1 --filter=blob:none --sparse \
    "$utpm_packages_repo" "$utpm_git_packages_dir" \
    || fail "failed to clone $utpm_packages_repo into $utpm_git_packages_dir"
  configure_utpm_sparse_checkout
fi

if [[ -z $utpm_packages_fork_owner ]]; then
  info "discovering GitHub login for utpm push remote"
  user_json=$(github_api "$UTPM_GITHUB_API/user") \
    || fail "failed to query GitHub user information with UTPM_GITHUB_TOKEN"
  utpm_packages_fork_owner=$(printf '%s' "$user_json" | tr -d '\n' | json_field login)
  [[ -n $utpm_packages_fork_owner ]] \
    || fail "failed to extract GitHub login from API response"
fi

if [[ -z $utpm_packages_push_url ]]; then
  utpm_packages_push_url="https://github.com/${utpm_packages_fork_owner}/packages.git"
fi

if ! git ls-remote "$utpm_packages_push_url" >/dev/null 2>&1; then
  info "creating fork ${utpm_packages_fork_owner}/packages"
  github_api -X POST "$UTPM_GITHUB_API/repos/${utpm_packages_upstream}/forks" >/dev/null \
    || fail "failed to create fork ${utpm_packages_fork_owner}/packages"

  fork_ready=0
  for _ in {1..20}; do
    if git ls-remote "$utpm_packages_push_url" >/dev/null 2>&1; then
      fork_ready=1
      break
    fi
    sleep 2
  done

  (( fork_ready )) \
    || fail "fork ${utpm_packages_fork_owner}/packages was not ready in time"
fi

git -C "$utpm_git_packages_dir" remote set-url --push origin "$utpm_packages_push_url" \
  || fail "failed to set utpm push remote to $utpm_packages_push_url"

prepare_utpm_main_branch
sync_utpm_fork_main_if_needed

info "all pre-flight checks passed — publishing $version via utpm"
utpm prj publish --bypass-warning -p .
create_or_reuse_utpm_pull_request
