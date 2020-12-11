#!/usr/bin/env bash

# Get the level to increment on (major|minor|patch)
LEVEL=${1:-patch}
# Grab current version (select index 2 of text split by \' )
CUR_VERSION=$(cat {REPO_NAME}/__init__.py | awk -F \' {'print $2'})
echo "Version: ${CUR_VERSION} and level '${LEVEL}'"
# Split into major/minor/patch
VERSION_BITS=(${CUR_VERSION//./ })
# Get number parts and increase last one by 1
VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}

if [[ "${LEVEL}" == "patch" ]];
then
    VNUM3=$((VNUM3+1))
elif [[ "${LEVEL}" == "minor" ]];
then
    VNUM2=$((VNUM2+1))
    VNUM3=0
elif [[ "${LEVEL}" == "major" ]];
then
    VNUM1=$((VNUM1+1))
    VNUM2=0
    VNUM3=0
else
    echo "Invalid level selected. Please enter one of major|minor|patch." && exit 1
fi

# Combine to new version
NEW_VERSION="${VNUM1}.${VNUM2}.${VNUM3}"
echo "New version: ${NEW_VERSION}"
