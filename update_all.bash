#!/usr/bin/env bash

set -uo pipefail
shopt -s nullglob

updated=0
failed=0

for dir in */; do
    if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf 'Updating %s...\n' "$dir"
        if git -C "$dir" pull --ff-only; then
            ((updated += 1))
        else
            printf 'Failed to update %s\n' "$dir" >&2
            ((failed += 1))
        fi
    fi
done

printf '\nUpdate complete: %d succeeded, %d failed.\n' "$updated" "$failed"
(( failed == 0 ))
