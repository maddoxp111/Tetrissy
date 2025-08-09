# CI Notes
- Uses `xcodebuild` on GitHub macOS runners to compile Release for iphoneos.
- Packages an **unsigned** IPA (no certs needed).
- Upload the IPA to Signulous for signing/install.
