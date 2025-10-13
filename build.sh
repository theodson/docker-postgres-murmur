#!/usr/bin/env bash

# you may want to set the env dockerid="yourid/"
test -z "${dockerid}" && {
  echo "set dockerid ENV"
  exit 1
}

dockertag=${dockerid}postgres-murmur:9.5.14-$(uname -m)

# Note: look at docker manifest or buildx for better multi architecture single image setup rather than tagging to distinguish platform.

if test $(uname -m) = 'arm64'; then
  # build in Apple Silicon environment
  docker build --no-cache -t "$dockertag" -f Dockerfile .
else
  # build in Intel environment
  dockertag="${dockerid}postgres-murmur:9.5.14"
  docker build --no-cache -t "$dockertag" -f Dockerfile .
fi

echo Finished Docker build, tagged with $dockertag
