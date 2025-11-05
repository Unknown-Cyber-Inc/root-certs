Collections of CA Certificates for verifying file signature:
   - Timestamps
   - Code Signing
   - Revocation Lists

Each collection has a `full_bundle.pem` file created by concatting all files in the `<collection>/bundles/` and `<collection>/singles/`. At the base of the repo, the file concatting each collection's `full_bundle.pem` is `cert_bundle.pem`.

Current Authorities collected:
   - Apple
   - Cisco
   - Microsoft
   - Mozilla
