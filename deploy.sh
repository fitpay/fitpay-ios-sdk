#! /bin/bash
set -x

if [ -z "$1" ]; then
    echo "Supply a previous version argument"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Supply a new version argument"
    exit 1
fi

# checkout develop
git checkout develop

# exit if not clean
if ! git diff-index --quiet HEAD --; then
  echo 'You have uncommitted changes - exit'
  exit 1
fi

# update versions
sed -i'.original' -e "s/s.version = '$1'/s.version = '$2'/g" FitpaySDK.podspec
sed -i'.original' -e "s/:tag => 'v$1'/:tag => 'v$2'/g" FitpaySDK.podspec
rm *.original
cd FitpaySDK
sed -i'.original' -e "s/$1/$2/g" Info.plist
rm *.original
cd ..

# update docs
# jazzy

# commit and push develop
git add -A
git commit -m "v$2"
git push

# switch to master and merge develop
git checkout master
git pull
git merge develop  -m "v$2 merge development"

# check for conflicts
CONFLICTS=$(git ls-files -u | wc -l)
if [ "$CONFLICTS" -gt 0 ] ; then
    echo "There is a merge conflict. Aborting"
    git merge --abort
    exit 1
fi

# push
git push

# create tag
git tag -a "v$2" -m "v$2"
git push origin "v$2"

# run cocoapods
pod trunk push FitpaySDK.podspec --allow-warnings
