#!/usr/bin/env bash

set -euo pipefail


# you may want to set the env DOCKERID="yourGitHubOrDockerHubId/"
test -z "${DOCKERID}" && {
  echo "set DOCKERID ENV - should end with /"
  exit 1
}
[[ "${DOCKERID}" != */ ]] && DOCKERID="${DOCKERID}/"
export POSTGRES_VERSION=9.5
export PLATFORM="${PLATFORM:-$(uname -m)}" # arm64, amd64 or all
export ACTION="${1:-build_$PLATFORM}" # build_arm64, build_amd64
export BUILD_ARGS=" --no-cache "

# Build and publish a multi-platform (amd64 + arm64) Docker image
# Final image tag: $DOCKERID/postgres-murmur:$POSTGRES_VERSION, e.g. theodson/postgres-murmur:9.5

IMAGE="${DOCKERID}postgres-murmur"
TAG="${POSTGRES_VERSION}"
FINAL_TAG="$IMAGE:$TAG"
AMD_TAG="$IMAGE:${TAG}-amd64"
ARM_TAG="$IMAGE:${TAG}-arm64"

# Older Buildx/BuildKit versions may not support --attest flags. Ensure no default
# attestations (provenance/SBOM) are attached by setting this env var as a guard.
export BUILDX_NO_DEFAULT_ATTESTATIONS=1

echo "Preparing Docker Buildx builder..."
if ! docker buildx inspect multi >/dev/null 2>&1; then
  docker buildx create --name multi --use --bootstrap >/dev/null
else
  docker buildx use multi >/dev/null
fi

build_amd64() {
  # Build and push amd64 using amd64-specific Dockerfile
  docker buildx build \
    --platform linux/amd64 $BUILD_ARGS \
    --provenance=false \
    --sbom=false \
    -t "$AMD_TAG" \
    -f amd64/Dockerfile \
    $1 \
    .
}

build_arm64() {
  # Build and push arm64 using arm64-specific Dockerfile
  docker buildx build \
    --platform linux/arm64 $BUILD_ARGS \
    --provenance=false \
    --sbom=false \
    -t "$ARM_TAG" \
    -f arm64/Dockerfile \
    $1 \
    .
}

resolve_platform_digest() {
  echo "Resolving exact PLATFORM MANIFEST digests for images..." >&2
  # Some docker buildx versions do not support Go template fields like .Manifests on imagetools output.
  # Parse the human-readable output instead: remember the digest from the most recent Name: line,
  # then when encountering the matching Platform: line, emit that digest.

  local tag="$1" arch="$2"
  docker buildx imagetools inspect "$tag" | awk -v arch="$arch" '
    tolower($1)=="name:" && match($0, /@sha256:[0-9a-f]+/) { d=substr($0, RSTART+1, RLENGTH-1) }
    tolower($1)=="platform:" {
      line=tolower($0)
      if (line ~ "linux/" arch) { print d; exit }
    }
  '
}


publish() {
  # Resolve platform manifest digests
  AMD_MANIFEST_DIGEST=$(resolve_platform_digest "$AMD_TAG" "amd64" | head -n1 | tr -d '\n')
  ARM_MANIFEST_DIGEST=$(resolve_platform_digest "$ARM_TAG" "arm64" | head -n1 | tr -d '\n')

  # Fallback: if parsing failed (e.g., single-manifest image without a Manifests list),
  # use the top-level Digest from imagetools (acceptable when tag is already a single image manifest)
  if [[ -z "${AMD_MANIFEST_DIGEST:-}" ]]; then
    AMD_MANIFEST_DIGEST=$(docker buildx imagetools inspect "$AMD_TAG" | awk 'tolower($1)=="digest:" {print $2; exit}')
  fi
  if [[ -z "${ARM_MANIFEST_DIGEST:-}" ]]; then
    ARM_MANIFEST_DIGEST=$(docker buildx imagetools inspect "$ARM_TAG" | awk 'tolower($1)=="digest:" {print $2; exit}')
  fi

  if [[ -z "${AMD_MANIFEST_DIGEST:-}" || -z "${ARM_MANIFEST_DIGEST:-}" ]]; then
    echo "Failed to resolve platform manifest digests for $AMD_TAG or $ARM_TAG" >&2
    echo "amd64: '${AMD_MANIFEST_DIGEST:-}'  arm64: '${ARM_MANIFEST_DIGEST:-}'" >&2
    echo "Raw inspect (amd64 tag):" >&2
    docker buildx imagetools inspect "$AMD_TAG" --format '{{json .}}' >&2 || true
    echo "Raw inspect (arm64 tag):" >&2
    docker buildx imagetools inspect "$ARM_TAG" --format '{{json .}}' >&2 || true
    exit 1
  fi

  echo "AMD64 platform manifest: $AMD_MANIFEST_DIGEST"
  echo "ARM64 platform manifest: $ARM_MANIFEST_DIGEST"

  echo "Creating and publishing multi-arch manifest $FINAL_TAG from exact digests..."
  # Remove any existing manifest to avoid stale references
  docker manifest rm "$FINAL_TAG" >/dev/null 2>&1 || true

  docker manifest create "$FINAL_TAG" \
    "$IMAGE@${AMD_MANIFEST_DIGEST}" \
    "$IMAGE@${ARM_MANIFEST_DIGEST}"

  docker manifest annotate "$FINAL_TAG" "$IMAGE@${AMD_MANIFEST_DIGEST}" --os linux --arch amd64
  docker manifest annotate "$FINAL_TAG" "$IMAGE@${ARM_MANIFEST_DIGEST}" --os linux --arch arm64

  docker manifest push "$FINAL_TAG"

  echo "Verifying manifest contents for $FINAL_TAG ..."
  docker buildx imagetools inspect "$FINAL_TAG"

  # Additional sanity: ensure no attestation manifests (in-toto) are present on per-arch images
  echo "Checking for unexpected attestation (in-toto) manifests on per-arch images..."
  if docker buildx imagetools inspect "$AMD_TAG" | grep -qi "attestation-manifest\|in-toto"; then
    echo "Error: Found attestation manifests on $AMD_TAG. Rebuild was expected to disable provenance/SBOM." >&2
    exit 2
  fi
  if docker buildx imagetools inspect "$ARM_TAG" | grep -qi "attestation-manifest\|in-toto"; then
    echo "Error: Found attestation manifests on $ARM_TAG. Rebuild was expected to disable provenance/SBOM." >&2
    exit 2
  fi

  echo "Done. Published multi-platform image: $FINAL_TAG"
}

case "${ACTION}" in
'all')
  echo "Building and pushing architecture-specific images..."
  build_arm64 "--push"
  build_amd64 "--push"
  publish
  ;;
'build')
  build_arm64 "--load"
  build_amd64 "--load"
  ;;
'build_arm64')
  build_arm64 "--load"
  ;;
'build_amd64')
  build_amd64 "--load"
  ;;
'push')
  build_arm64 "--push"
  build_amd64 "--push"
  ;;
'push_arm64')
  build_arm64 "--push"
  ;;
'push_amd64')
  build_amd64 "--push"
  ;;
'publish')
# publish all arm64 and amd64
  publish
  ;;
esac
