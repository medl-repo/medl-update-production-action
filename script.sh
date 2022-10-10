#!/usr/bin/env bash

set -eu

BASE_BRANCH=$1
MERGE_BRANCH=$2

git branch "$BASE_BRANCH" "origin/$BASE_BRANCH"

# Check if staging / production have any changes
if git diff -M -C -B --find-copies-harder --exit-code "$MERGE_BRANCH" "$BASE_BRANCH" &>/dev/null; then
    # No changes
    exit 0
fi

set -x

EMAILS=$(git shortlog -nse "$BASE_BRANCH".."$MERGE_BRANCH" | awk -F '<' '{ print $2 }' | awk -F '>' '{ print $1 }' | grep -v '@users.noreply.github.com$')

USERNAMES=()
for E in $EMAILS; do
    U=$(curl -s "https://api.github.com/search/users?q=$E" | jq -r '.items[0].login')
    if [[ "$U" != "null" ]]; then
        USERNAMES+=("$U")
    fi

    echo "$E -> $U"
done
USERNAMES_JOINED=$(
    IFS=,
    echo "${USERNAMES[*]}"
)

gh pr create -B "$BASE_BRANCH" -H "$MERGE_BRANCH" --title 'Auto Update Production' --body 'Created by Github CI' -a "$USERNAMES_JOINED" || true
