#!/bin/bash
set -x -e
GITHUB_ACCESS_TOKEN=$1
TAG=$2 # Release name/tag

# For tags `actions/checkout@v2` action fetches a tag's commit, but
# not the tag annotation itself. Let's refetch the tag from origin.
# This makes `git show --no-patch --format=%n $TAG` work again.
git tag --delete "$TAG"
git fetch --tags

function release_notes() {
   echo "# Release notes"

   git show --no-patch --format=%n "$TAG" |
      sed -e '1,/Release notes/d'
   echo ""

   COMMITS=commits.txt

   if [ -f "$COMMITS" ]; then
      {
         echo "# Dependency commits"
         echo ""
         cat "$COMMITS"
         echo ""
      }
   fi
}

release_notes >release_notes.md

# Try to create a release
jq --null-input --arg tag "$TAG" \
   --rawfile body release_notes.md \
   '{"tag_name": $tag, "name": $tag, "body": $body}' |
   curl -v \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
      -H 'Content-Type: application/json' \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/releases" \
      -d "@-"

rm -f release_notes.md

# Get asset upload url, drop "quotes" around it and {parameters} at the end
upload_url=$(curl \
   -H "Accept: application/vnd.github+json" \
   -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
   "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/$TAG" |
   jq -r '.upload_url | rtrimstr("{?name,label}")')

echo "upload_url=$upload_url"

for FILE in *.vsix; do
   # Upload $FILE as an asset to the release
   curl \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
      -H 'Content-Type: application/zip' \
      --data-binary "@$FILE" \
      "$upload_url?name=$FILE"
done
