#!/usr/bin/env bash
# Sign a container image by DIGEST, generate its SBOM (syft) and attach three things to it with cosign:
#   1. a signature
#   2. the SBOM as an attestation (predicate type spdxjson)
#   3. a SLSA v1 provenance attestation
# The SBOM and the provenance statement are also written to --out so they can be uploaded as release assets.
#
# Keyless (CI, the default):  needs an OIDC token (GitHub Actions: `permissions: id-token: write`), network access to
#   fulcio.sigstore.dev, rekor.sigstore.dev and tuf-repo-cdn.sigstore.dev, and registry credentials in the docker config.
#   No key is stored anywhere; the signer is the workflow identity.
# Key mode (--key, local tests only): signs with a local cosign key and does not touch the public Sigstore services.
#
#   .github/scripts/sign-and-attest.sh --image ghcr.io/zyvorai/zyvor-packetwolf@sha256:<64 hex> [options]
#
# Options:
#   --image REF@sha256:DIGEST   required; a tag is refused (a tag can move between the scan and the signature)
#   --out DIR                   where sbom.spdx.json and provenance.json go (default ./attestations)
#   --sbom-format FMT           spdx-json (default) or cyclonedx-json
#   --source-repo URL --source-commit SHA   what the image was built from (recorded in the provenance)
#   --builder-id URL            who signed (default: the GitHub Actions run when in CI, else "local")
#   --invocation-id URL         the run that produced this attestation (default: the Actions run URL)
#   --key FILE                  use this cosign private key instead of keyless (tests only)
#   --insecure-registry         plain-HTTP / self-signed registry (local test registry only)
#   --no-tlog                   do not upload to the Rekor transparency log (implied by --key)
#   --verify-identity ID --verify-issuer URL   after signing, run the verify commands for this identity
#                                              (keyless; also what the public docs tell users to run)
#   --dry-run                   print what would run, change nothing
#
# Environment: COSIGN_PASSWORD (key mode), COSIGN_YES=true is set here. Exits non-zero on the first failure.
set -euo pipefail

IMAGE="" OUT="attestations" SBOM_FMT="spdx-json" KEY="" INSECURE=0 TLOG=1 DRY=0
SRC_REPO="" SRC_COMMIT="" BUILDER="" INVOCATION="" V_ID="" V_ISS=""

usage() { sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit "${1:-2}"; }
die() { echo "sign-and-attest: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --image) IMAGE="${2:?}"; shift 2 ;;
    --out) OUT="${2:?}"; shift 2 ;;
    --sbom-format) SBOM_FMT="${2:?}"; shift 2 ;;
    --source-repo) SRC_REPO="${2:?}"; shift 2 ;;
    --source-commit) SRC_COMMIT="${2:?}"; shift 2 ;;
    --builder-id) BUILDER="${2:?}"; shift 2 ;;
    --invocation-id) INVOCATION="${2:?}"; shift 2 ;;
    --key) KEY="${2:?}"; TLOG=0; shift 2 ;;
    --insecure-registry) INSECURE=1; shift ;;
    --no-tlog) TLOG=0; shift ;;
    --verify-identity) V_ID="${2:?}"; shift 2 ;;
    --verify-issuer) V_ISS="${2:?}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
done

[ -n "$IMAGE" ] || usage
[[ "$IMAGE" =~ ^[a-z0-9._:/-]+@sha256:[0-9a-f]{64}$ ]] || die "--image must be NAME@sha256:<64 hex>, got: $IMAGE"
case "$SBOM_FMT" in
  spdx-json) PRED_TYPE=spdxjson ;;
  cyclonedx-json) PRED_TYPE=cyclonedx ;;
  *) die "--sbom-format must be spdx-json or cyclonedx-json" ;;
esac
[[ "$SRC_COMMIT" =~ ^([0-9a-f]{40})?$ ]] || die "--source-commit must be a 40 hex commit id"
for t in cosign syft jq; do command -v "$t" >/dev/null || die "$t not found in PATH"; done

if [ -n "$KEY" ]; then
  [ -f "$KEY" ] || die "key file not found: $KEY"
  MODE="key"
else
  MODE="keyless"
  # Keyless needs an ambient OIDC token. Fail early with a clear message instead of an interactive browser prompt.
  if [ "$DRY" = 0 ] && [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] && [ -z "${SIGSTORE_ID_TOKEN:-}" ]; then
    die "keyless signing needs an OIDC token (in GitHub Actions: permissions: id-token: write). Use --key for local tests."
  fi
fi
[ -n "$BUILDER" ] || BUILDER="${GITHUB_SERVER_URL:+$GITHUB_SERVER_URL/}${GITHUB_WORKFLOW_REF:-local}"
[ -n "$INVOCATION" ] || INVOCATION="${GITHUB_SERVER_URL:-}${GITHUB_SERVER_URL:+/}${GITHUB_REPOSITORY:-}${GITHUB_RUN_ID:+/actions/runs/$GITHUB_RUN_ID}"
[ -n "$SRC_COMMIT" ] || SRC_COMMIT="${GITHUB_SHA:-}"

export COSIGN_YES=true
COSIGN_FLAGS=()
[ "$INSECURE" = 1 ] && COSIGN_FLAGS+=(--allow-insecure-registry)
SIGN_FLAGS=(${COSIGN_FLAGS[@]+"${COSIGN_FLAGS[@]}"})
if [ "$MODE" = key ]; then SIGN_FLAGS+=(--key "$KEY"); fi
if [ "$TLOG" = 0 ]; then SIGN_FLAGS+=(--use-signing-config=false --tlog-upload=false); fi
[ "$INSECURE" = 1 ] && export SYFT_REGISTRY_INSECURE_USE_HTTP=true

run() { echo "+ $*"; [ "$DRY" = 1 ] || "$@"; }

SBOM="$OUT/sbom.$([ "$SBOM_FMT" = spdx-json ] && echo spdx || echo cdx).json"
PROV="$OUT/provenance.json"
mkdir -p "$OUT"
echo "image:  $IMAGE"
echo "mode:   $MODE$([ "$TLOG" = 0 ] && echo ' (no transparency log)')"
echo "sbom:   $SBOM_FMT -> $SBOM"

# 1. SBOM of exactly this digest
run syft "registry:$IMAGE" --quiet -o "$SBOM_FMT=$SBOM"
[ "$DRY" = 1 ] || { [ -s "$SBOM" ] || die "syft produced no SBOM"; }

# 2. SLSA v1 provenance predicate. Honest scope: this records WHO attested this digest, from which run, and the
#    source commit the caller declared. It does not claim a hermetic build: the image is built elsewhere and signed here.
if [ "$DRY" = 0 ]; then
  DIGEST="${IMAGE##*@sha256:}"
  jq -n \
    --arg image "${IMAGE%@*}" --arg digest "$DIGEST" --arg builder "$BUILDER" --arg inv "$INVOCATION" \
    --arg repo "$SRC_REPO" --arg commit "$SRC_COMMIT" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
    { buildDefinition: {
        buildType: "https://zyvor.dev/slsa/attest-prebuilt-image/v1",
        externalParameters: ({image: ($image + "@sha256:" + $digest)}
          + (if $repo != "" then {sourceRepository: $repo} else {} end)
          + (if $commit != "" then {sourceCommit: $commit} else {} end)),
        internalParameters: {note: "The image was built outside this workflow; this attestation binds the digest to the signing run and the declared source commit."},
        resolvedDependencies: (if $commit != "" and $repo != "" then [{uri: ($repo + "@" + $commit), digest: {gitCommit: $commit}}] else [] end) },
      runDetails: {
        builder: {id: $builder},
        metadata: ({finishedOn: $now} + (if $inv != "" then {invocationId: $inv} else {} end)) } }' > "$PROV"
else
  echo "+ (write SLSA provenance predicate to $PROV)"
fi

# 3. sign, then attach the SBOM and the provenance
run cosign sign ${SIGN_FLAGS[@]+"${SIGN_FLAGS[@]}"} "$IMAGE"
run cosign attest ${SIGN_FLAGS[@]+"${SIGN_FLAGS[@]}"} --type "$PRED_TYPE" --predicate "$SBOM" "$IMAGE"
run cosign attest ${SIGN_FLAGS[@]+"${SIGN_FLAGS[@]}"} --type slsaprovenance1 --predicate "$PROV" "$IMAGE"

# 4. verify what we just published (the same commands the public docs give)
if [ "$MODE" = key ]; then
  PUB="${KEY%.key}.pub"; [ -f "$PUB" ] || die "public key $PUB not found for verification"
  VERIFY=(${COSIGN_FLAGS[@]+"${COSIGN_FLAGS[@]}"} --key "$PUB" --insecure-ignore-tlog=true)
elif [ -n "$V_ID" ] && [ -n "$V_ISS" ]; then
  VERIFY=(${COSIGN_FLAGS[@]+"${COSIGN_FLAGS[@]}"} --certificate-identity "$V_ID" --certificate-oidc-issuer "$V_ISS")
else
  VERIFY=()
  echo "note: keyless verification skipped (pass --verify-identity and --verify-issuer)"
fi
if [ ${#VERIFY[@]} -gt 0 ]; then
  run cosign verify ${VERIFY[@]+"${VERIFY[@]}"} "$IMAGE" >/dev/null
  run cosign verify-attestation ${VERIFY[@]+"${VERIFY[@]}"} --type "$PRED_TYPE" "$IMAGE" >/dev/null
  run cosign verify-attestation ${VERIFY[@]+"${VERIFY[@]}"} --type slsaprovenance1 "$IMAGE" >/dev/null
  [ "$DRY" = 1 ] || echo "verified: signature, $PRED_TYPE attestation, slsaprovenance1 attestation"
fi
echo "done. assets for the release: $SBOM $PROV"
