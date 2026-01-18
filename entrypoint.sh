#!/bin/bash

set -o pipefail

# Logging helper function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

log "🚀 Starting Firebase Distribution GitHub Action"

# Required since https://github.blog/2022-04-12-git-security-vulnerability-announced
log "📝 Configuring git safe directory: $GITHUB_WORKSPACE"
if git config --global --add safe.directory "$GITHUB_WORKSPACE"; then
    log "✅ Git safe directory configured successfully"
else
    log "⚠️  Warning: Failed to configure git safe directory (non-fatal)"
fi

RELEASE_NOTES=""
RELEASE_NOTES_FILE=""

TOKEN_DEPRECATED_WARNING_MESSAGE="⚠ This action will stop working with the next future major version of firebase-tools! Migrate to Service Account. See more: https://github.com/wzieba/Firebase-Distribution-Github-Action/wiki/FIREBASE_TOKEN-migration"

# Validate required inputs
log "🔍 Validating required inputs..."
if [[ -z "${INPUT_FILE}" ]]; then
    log "❌ ERROR: INPUT_FILE is required but not provided"
    exit 1
fi

if [[ -z "${INPUT_APPID}" ]]; then
    log "❌ ERROR: INPUT_APPID is required but not provided"
    exit 1
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
    log "❌ ERROR: File not found: ${INPUT_FILE}"
    exit 1
fi

log "✅ Required inputs validated"
log "   - File: ${INPUT_FILE}"
log "   - App ID: ${INPUT_APPID}"
log "   - Groups: ${INPUT_GROUPS:-not specified}"
log "   - Testers: ${INPUT_TESTERS:-not specified}"
log "   - Debug mode: ${INPUT_DEBUG:-false}"

# Handle release notes
log "📋 Processing release notes..."
if [[ -z ${INPUT_RELEASENOTES} ]]; then
    log "   No release notes provided, extracting from git log"
    if RELEASE_NOTES="$(git log -1 --pretty=short 2>&1)"; then
        log "✅ Release notes extracted from git log (${#RELEASE_NOTES} characters)"
    else
        log "⚠️  Warning: Failed to extract release notes from git log"
        RELEASE_NOTES=""
    fi
else
    RELEASE_NOTES=${INPUT_RELEASENOTES}
    log "✅ Using provided release notes (${#RELEASE_NOTES} characters)"
fi

if [[ ${INPUT_RELEASENOTESFILE} ]]; then
    log "   Release notes file specified, overriding release notes"
    RELEASE_NOTES=""
    RELEASE_NOTES_FILE=${INPUT_RELEASENOTESFILE}
    if [[ -f "${RELEASE_NOTES_FILE}" ]]; then
        log "✅ Release notes file found: ${RELEASE_NOTES_FILE}"
    else
        log "⚠️  Warning: Release notes file not found: ${RELEASE_NOTES_FILE}"
    fi
fi

# Handle service credentials
log "🔐 Configuring authentication..."
if [ -n "${INPUT_SERVICECREDENTIALSFILE}" ] ; then
    if [[ -f "${INPUT_SERVICECREDENTIALSFILE}" ]]; then
        export GOOGLE_APPLICATION_CREDENTIALS="${INPUT_SERVICECREDENTIALSFILE}"
        log "✅ Using service credentials file: ${INPUT_SERVICECREDENTIALSFILE}"
    else
        log "❌ ERROR: Service credentials file not found: ${INPUT_SERVICECREDENTIALSFILE}"
        exit 1
    fi
fi

if [ -n "${INPUT_SERVICECREDENTIALSFILECONTENT}" ] ; then
    log "   Creating service credentials from content"
    if cat <<< "${INPUT_SERVICECREDENTIALSFILECONTENT}" > service_credentials_content.json; then
        export GOOGLE_APPLICATION_CREDENTIALS="service_credentials_content.json"
        log "✅ Service credentials file created from content"
    else
        log "❌ ERROR: Failed to create service credentials file"
        exit 1
    fi
fi

if [ -n "${INPUT_TOKEN}" ] ; then
    echo ${TOKEN_DEPRECATED_WARNING_MESSAGE}
    export FIREBASE_TOKEN="${INPUT_TOKEN}"
    log "⚠️  Using FIREBASE_TOKEN (deprecated - consider migrating to service account)"
fi

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]] && [[ -z "${FIREBASE_TOKEN}" ]]; then
    log "❌ ERROR: No authentication method provided. Set either INPUT_SERVICECREDENTIALSFILE, INPUT_SERVICECREDENTIALSFILECONTENT, or INPUT_TOKEN"
    exit 1
fi

# Build firebase command
log "🔨 Building Firebase command..."
FIREBASE_CMD="firebase appdistribution:distribute \"${INPUT_FILE}\" --app \"${INPUT_APPID}\""

if [[ -n "${INPUT_GROUPS}" ]]; then
    FIREBASE_CMD="${FIREBASE_CMD} --groups \"${INPUT_GROUPS}\""
fi

if [[ -n "${INPUT_TESTERS}" ]]; then
    FIREBASE_CMD="${FIREBASE_CMD} --testers \"${INPUT_TESTERS}\""
fi

if [[ -n "${RELEASE_NOTES}" ]]; then
    FIREBASE_CMD="${FIREBASE_CMD} --release-notes \"${RELEASE_NOTES}\""
fi

if [[ -n "${INPUT_RELEASENOTESFILE}" ]]; then
    FIREBASE_CMD="${FIREBASE_CMD} --release-notes-file \"${RELEASE_NOTES_FILE}\""
fi

if (( ${INPUT_DEBUG:-0} )); then
    FIREBASE_CMD="${FIREBASE_CMD} --debug"
    log "   Debug mode enabled"
fi

log "📤 Executing Firebase distribution command..."
log "   Command: ${FIREBASE_CMD}"

# Execute firebase command and capture output
firebase \
        appdistribution:distribute \
        "$INPUT_FILE" \
        --app "$INPUT_APPID" \
        ${INPUT_GROUPS:+ --groups "$INPUT_GROUPS"} \
        ${INPUT_TESTERS:+ --testers "$INPUT_TESTERS"} \
        ${RELEASE_NOTES:+ --release-notes "${RELEASE_NOTES}"} \
        ${INPUT_RELEASENOTESFILE:+ --release-notes-file "${RELEASE_NOTES_FILE}"} \
        $( (( ${INPUT_DEBUG:-0} )) && printf %s '--debug' ) 2>&1 |
{
    while read -r line; do
      echo "$line"

      if [[ $line == *"View this release in the Firebase console"* ]]; then
        CONSOLE_URI=$(echo "$line" | sed -e 's/.*: //' -e 's/^ *//;s/ *$//')
        log "✅ Extracted console URI: ${CONSOLE_URI}"
        echo "FIREBASE_CONSOLE_URI=$CONSOLE_URI" >>"$GITHUB_OUTPUT"
      elif [[ $line == *"Share this release with testers who have access"* ]]; then
        TESTING_URI=$(echo "$line" | sed -e 's/.*: //' -e 's/^ *//;s/ *$//')
        log "✅ Extracted testing URI: ${TESTING_URI}"
        echo "TESTING_URI=$TESTING_URI" >>"$GITHUB_OUTPUT"
      elif [[ $line == *"Download the release binary"* ]]; then
        BINARY_URI=$(echo "$line" | sed -e 's/.*: //' -e 's/^ *//;s/ *$//')
        log "✅ Extracted binary download URI: ${BINARY_URI}"
        echo "BINARY_DOWNLOAD_URI=$BINARY_URI" >>"$GITHUB_OUTPUT"
      fi
    done
}

# Capture exit code (pipefail ensures we get the exit code from firebase command)
EXIT_CODE=${PIPESTATUS[0]}

if [[ $EXIT_CODE -eq 0 ]]; then
    log "✅ Firebase distribution completed successfully"
else
    log "❌ ERROR: Firebase distribution failed with exit code: ${EXIT_CODE}"
    exit $EXIT_CODE
fi
