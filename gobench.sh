#!/bin/bash

BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[32m"
RESET="\033[0m"

die_if_not_installed() {
    if ! [ -x "$(command -v $1)" ]; then
        echo -e "  ... quitting because ${BOLD}$1${RESET} is not installed"
        exit 1
    fi
}

ROOT=.
BENCH_FILTER=${1-.}
BENCH_BASE=/tmp/gobench
BENCH_ID=$(echo -n "$BENCH_FILTER" | /usr/bin/md5sum | awk '{ print $1 }')

BANNER="${GREEN}🐢${RESET} gobench is ..."

if [ ! -d "$ROOT/.git" ]; then
    echo "  ... quitting because '$ROOT' is not a git repository :/"
    exit 1
fi

die_if_not_installed 'git'
die_if_not_installed 'go'
die_if_not_installed 'benchcmp'

REF_COMMIT_ID=$(git log --format="%H" -n 1)
REF_BENCH_FILE="$BENCH_BASE/$REF_COMMIT_ID.$BENCH_ID.bench"
NEW_BENCH_FILE="$BENCH_BASE/$REF_COMMIT_ID.$BENCH_ID.withchanges.bench"
DIFF_FILE="$BENCH_BASE/$REF_COMMIT_ID.$BENCH_ID.diff"

die_if_clean() {
    if [ -z "$(git status --porcelain)" ]; then
      echo "  ... quitting because the working directory is clean ^_^"
      exit 0
    fi
}

run_ref_benchmarks() {
    rm -rf "$REF_BENCH_FILE"
    mkdir -p "$BENCH_BASE"
    go test -run=NONE -bench="$BENCH_FILTER" -benchmem $ROOT/... > "$REF_BENCH_FILE"
}

run_new_benchmarks() {
    mkdir -p "$BENCH_BASE"
    echo "  ... creating a new benchmark profile for the stashed changes" 
    go test -run=NONE -bench="$BENCH_FILTER" -benchmem $ROOT/... > "$NEW_BENCH_FILE"
}

run_ref_benchmarks_if_needed() {
    if [ ! -e "$REF_BENCH_FILE" ]; then
        echo -e "  ... creating the reference benchmark profile for commit $REF_COMMIT_ID"
        run_ref_benchmarks
    else
        echo -e "  ... using a cached reference benchmark profile"
    fi
}

compare() {
    benchcmp -mag -changed "$REF_BENCH_FILE" "$NEW_BENCH_FILE" > "$DIFF_FILE"
    out=$(cat "$DIFF_FILE")
    echo
    while read -r line; do
        if [[ $line == *"+"* ]]; then
            echo -e "${RED}$line${RESET}"
        elif [[ $line == *"-"* ]]; then
            echo -e "${GREEN}$line${RESET}"
        else
            echo -e "${BOLD}$line${RESET}"
        fi
    done <<< $out
}

echo -e "${BANNER}\n"

die_if_clean

echo "  ... stashing the changes"
git stash -k -u > /dev/null

run_ref_benchmarks_if_needed

echo "  ... restoring the changes"
git stash pop > /dev/null

run_new_benchmarks

echo "  ... done!"

compare 
