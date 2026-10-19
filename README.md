# GlassWeb Cloud Build (iOS 16.6.1 + TrollStore)

This repository is configured for a GitHub Actions macOS build so you do not need a local Mac.

## What it does
- SwiftUI app with WKWebView
- Address bar, back/forward, reload, home, save-home and bookmark actions
- UserDefaults for home URL and bookmark URLs
- Default WebKit website data store
- iOS 16-compatible translucent material styling
- GitHub Actions workflow builds the iOS app without Apple signing and packages it as `GlassWeb-unsigned.ipa`

## Build it from an iPhone or Windows PC
1. Download and unzip this project.
2. Sign in to GitHub in your browser and create a new repository named `GlassWeb`.
3. Upload the *contents* of this folder to the repository, preserving `.github/workflows/build-ipa.yml` (GitHub may hide dot folders in some upload flows; if so, enable showing hidden files or create the workflow file directly in GitHub).
4. Open the repository's **Actions** tab. If prompted, enable GitHub Actions.
5. Choose **Build GlassWeb IPA (unsigned)** in the left sidebar and press **Run workflow**. A push to the `main` branch also triggers a build.
6. Wait for the run to finish successfully. Open that run, scroll to **Artifacts**, and download `GlassWeb-unsigned-IPA`.
7. Extract the artifact ZIP; it contains `GlassWeb-unsigned.ipa` and `xcodebuild.log`.
8. Transfer `GlassWeb-unsigned.ipa` to your iPhone (Files/iCloud Drive, AirDrop from another device, or a private cloud drive). Open it in TrollStore and install it.
9. Test on iOS 16.6.1: launch, load a website, navigate, reload, save home, add a bookmark, and verify login/cookie persistence for your chosen site.

## Important notes
- The default URL is `https://example.com`. The target site is not yet specified. Edit `AppConfig.defaultURL` in `GlassWeb/BrowserView.swift` later and rebuild if you want a fixed website.
- This workflow intentionally produces an unsigned IPA package. TrollStore is designed to install IPAs on supported versions, but successful installation/runtime still must be verified on the actual device.
- This does not create an App Store-ready signed release. It is specifically an unsigned package intended for TrollStore testing.
- The project uses XcodeGen to generate an Xcode project on the cloud runner; the checked-in `project.yml` is the source of project configuration.
- GitHub Actions runner availability and usage limits depend on GitHub's current policies/account. Public repositories generally have access to standard hosted runners; see GitHub's official runner documentation.
- Never commit Apple certificates, private keys, passwords, or tokens to this repository.
