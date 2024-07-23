#!/bin/bash
set -x -e
VSCE_TOKEN=$1
OVSX_TOKEN=$2
TAG=$3 # For master it's 24.0.999, while for tag it's the tag itself

function make_change_log() {
   echo "# Release notes"
   echo ""
   for TAG_ID in $(git tag --list --sort=-v:refname '2*'); do
      DATE=$(git show --no-patch --format=Date:%ad --date=short "$TAG_ID" |
         grep Date: | sed -e s/Date://)
      echo "## $TAG_ID ($DATE)"
      git show --no-patch --format=%n "$TAG_ID" | sed -e '1,/Release notes/d'
   done
}

function os_to_node_platform() {
   case "$1" in
   ubuntu*)
      echo -n "linux-x64"
      ;;
   macos-12)
      echo -n "darwin-x64"
      ;;
   macos-14)
      echo -n "darwin-arm64"
      ;;
   esac
}

ext_dir=integration/vscode/ada

(
   cd "$ext_dir"

   # Set package version based on the Git tag
   sed -i -e "/version/s/[0-9][0-9.]*/$TAG/" package.json

   # Install NPM deps
   npm -v
   node -v
   which node
   npm install

   # Create change log
   make_change_log >CHANGELOG.md
)

ls -l

# At the moment we only create VSIX-es for macOS on GitHub. Other platforms are
# provided elsewhere.
# shellcheck disable=SC2043
for OS in macos-12 macos-14 ubuntu-20.04; do
   source=als-"$OS"
   if [ -d "$source" ]; then
      # Make sure the file are executable
      chmod -R -v +x "$source"
      # Copy the binary in place
      rsync -rva "$source"/ "$ext_dir"/
      # Delete debug info
      rm -rf -v "$ext_dir"/{arm,arm64,x64}/{linux,darwin,win32}/*.{debug,dSYM}

      (
         cd "$ext_dir"
         # Create the VSIX
         TARGET="$(os_to_node_platform_arch $OS)"
         npx vsce package --target "$TARGET"
         mv -v ./*.vsix ada-$TARGET-$TAG.vsix
      )

      # Cleanup the binary directory
      rm -rf -v "$ext_dir"/{arm,arm64,x64}
   fi
done

# Move all .vsix packages to the root of the checkout
mv -v "$ext_dir"/*.vsix .
# Discard the package.json and package-lock.json changes
git checkout "$ext_dir"/package*.json
