#!/usr/bin/env bash

set -e

# directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOC_FILE="$DIR/../IronmanChecker.toc"

if [[ ! -e "$TOC_FILE" ]]; then
    echo "No toc file found at $TOC_FILE"
fi

current_version=$(cat "$TOC_FILE" | grep -Po 'Version:\s*([0-9.]+)' | sed 's/Version://; s/\s*//')

major="$(echo "$current_version" | awk -F'.' '{print $1}')"
minor="$(echo "$current_version" | awk -F'.' '{print $2}')"
patch="$(echo "$current_version" | awk -F'.' '{print $3}')"

new_version="${major}.${minor}.$((patch + 1))"

read -p "New version is $new_version, proceed? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

if ! git diff --quiet; then
    echo "Unclean tree, clean up and try again."
    exit 1
fi

sed -i "s/$current_version/$new_version/g" "$TOC_FILE"

tag="$new_version"
git add "$TOC_FILE"
git commit -m "Bumping version $new_version"
git tag -a "$tag" -m "$tag"

echo "Bump commit added:"
git log -p -n1

echo "Review and run:"
echo "git push && git push origin $tag"
