# Firebase App Distribution Github Action

<a href="https://github.com/adrianbudzynski/firebase-distribution-github-action/actions">![](https://github.com/adrianbudzynski/firebase-distribution-github-action/workflows/Sample%20workflow%20for%20Firebase%20Distribution%20action/badge.svg)</a>
<a href="https://github.com/adrianbudzynski/firebase-distribution-github-action/releases">![](https://img.shields.io/github/v/release/adrianbudzynski/firebase-distribution-github-action)</a>

> **Note:** This is a fork of [wzieba/Firebase-Distribution-Github-Action](https://github.com/wzieba/Firebase-Distribution-Github-Action). This action uses a Docker container image hosted at `ghcr.io/adrianbudzynski/firebase-distribution-github-action:latest`.

This action uploads artifacts (.apk, .aab or .ipa) to Firebase App Distribution.

## Inputs

### `appId`

**Required** App id can be found in the Firebase console in your Projects Settings, under Your apps. It is in the following format 1:1234567890123942955466829:android:1234567890abc123abc123

### `token`

⚠️ Deprecated! Don't use it. Firebase team deprecated this option and it will soon be removed.

Use `serviceCredentialsFileContent` instead.

~**Required** Upload token - see Firebase CLI Reference (tldr; run `firebase login:ci` command to get your token).~

### `serviceCredentialsFileContent`
**Required** Content of Service Credentials private key JSON file.

### `serviceCredentialsFile`

Service Credentials File - The path or HTTP URL to your Service Account private key JSON file.

**Required** only if you don't use `serviceCredentialsFileContent`.

### `file`

**Required** Artifact to upload (.apk, .aab or .ipa)

### `groups`

Distribution groups. Comma-separated list of group names.

### `testers`

Distribution testers. Comma-separated list of email addresses of the testers you want to invite.

### `releaseNotes`

Release notes visible on release page. If not specified, the action will automatically extract the last commit's:
 - hash
 - author
 - message
 
### `releaseNotesFile`

Specify the release note path to a plain text file.

### `debug`

Flag to enable verbose log output. Set to `true` to print detailed debugging information. Default value is `false`.

## Outputs

### `FIREBASE_CONSOLE_URI`

Link to uploaded release in the Firebase console.

### `TESTING_URI`

Link to share release with testers who have access.

### `BINARY_DOWNLOAD_URI`

Link to download the release binary (link expires in 1 hour).

## Usage

This action uses Docker and requires either `serviceCredentialsFileContent` or `serviceCredentialsFile` for authentication. The `token` input is deprecated and should not be used.

### Versioning

You can use:
- `@latest` - Always uses the latest version (recommended for most cases)
- `@v1` - Pins to a specific major version
- `@v1.0.0` - Pins to a specific version tag

## Sample usage

```yaml
name: Build & upload to Firebase App Distribution 

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4
    - name: set up JDK 1.8
      uses: actions/setup-java@v4
      with:
        java-version: '8'
    - name: build release 
      run: ./gradlew assembleRelease
    - name: upload artifact to Firebase App Distribution
      uses: adrianbudzynski/firebase-distribution-github-action@latest
      with:
        appId: ${{secrets.FIREBASE_APP_ID}}
        serviceCredentialsFileContent: ${{ secrets.CREDENTIAL_FILE_CONTENT }}
        groups: testers
        file: app/build/outputs/apk/release/app-release-unsigned.apk
```
