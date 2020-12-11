#!/usr/bin/env bash

# Grab current branch
CURRENT_BRANCH=$(git branch | sed -n '/\* /s///p')
TARGET_BRANCH="master"

if [[ ! "${CURRENT_BRANCH}" == "${TARGET_BRANCH}" ]]
then
  echo "Script aborted. Branch must be set on '${TARGET_BRANCH}'.
  Current branch is '${CURRENT_BRANCH}'" && exit 1 || return 1
fi

# Grab current date
DATE=$(date +"%Y-%m-%d")
TAG="deploy/${DATE}"
TAG_MSG="Tag for ${1:-updates as of ${DATE}}"

read -p "Confirm (y/n): Tagging '${TAG}' with message '${TAG_MSG}'..." -n 1 -r
echo # (optional) move to a new line
if [[ ${REPLY} =~ ^[Yy]$ ]]
then
  echo "Tagging branch"
  # Tag branch
  git tag -a "${TAG}" -m "${TAG_MSG}"
  # Push to branch
  git push origin "${TAG}"
  # Push to master to ensure master's up-to-date
  git push origin master
else
  echo "Cancelled tag"
fi
