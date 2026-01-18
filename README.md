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

## Setting Up Service Account

This action requires a service account with proper permissions to upload builds to Firebase App Distribution. Follow these steps to create and configure a service account:

### Step 1: Access Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project

### Step 2: Create Service Account

1. Navigate to **IAM & Admin** → **Service Accounts**
   - Direct link: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Click **Create Service Account**
3. Fill in the details:
   - **Service account name**: e.g., `firebase-app-distribution`
   - **Service account ID**: auto-generated (or customize)
   - **Description**: e.g., "Service account for Firebase App Distribution CI/CD"
4. Click **Create and Continue**

### Step 3: Grant Required Permissions

1. In the **Grant this service account access to project** section, click **Add Another Role**
2. Search for and select **Firebase App Distribution Admin** (`roles/firebaseappdistro.admin`)
   - ⚠️ **Important**: This role is required for uploading builds. The Viewer role is not sufficient.
3. Click **Continue**, then **Done**

> **Note**: If the role doesn't appear in the dropdown, you can grant it manually:
> - Go to **IAM & Admin** → **IAM**
> - Find your service account and click **Edit**
> - Click **Add Another Role** and search for `firebaseappdistro.admin`

### Step 4: Create and Download JSON Key

1. Click on the service account you just created
2. Go to the **Keys** tab
3. Click **Add Key** → **Create new key**
4. Select **JSON** format
5. Click **Create** (this will download the JSON key file)

### Step 5: Store Credentials in GitHub Secrets

1. Open the downloaded JSON file and copy its entire contents
2. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Create a secret named `FIREBASE_SERVICE_ACCOUNT_KEY` (or `CREDENTIAL_FILE_CONTENT` as shown in the example)
5. Paste the entire JSON file content as the value
6. Click **Add secret**

### Step 6: Get Your App ID

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon) → **Your apps**
4. Find your app and copy the **App ID** (format: `1:1234567890123942955466829:android:1234567890abc123abc123`)
5. Create a GitHub secret named `FIREBASE_APP_ID` with this value

### Troubleshooting

- **403 Permission Denied**: Ensure the service account has the `roles/firebaseappdistro.admin` role assigned
- **Role not found**: You need Owner or IAM Admin permissions on the project to create service accounts and assign roles
- **Wrong App ID**: Verify the `appId` matches your Firebase app ID from Project Settings

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
