# Releasing

- Update the version number in `lib/honeycomb/beeline/version`.
- Update `CHANGELOG.md` with the changes since the last release.
- Commit changes, push, and open a release preparation pull request for review.
- Once the pull request is merged, fetch the updated `main` branch.
- Apply a tag for the new version on the merged commit: vX.Y.Z, for example v1.1.2.
- Push the new version tag up to the project repository to kick off build and artifact publishing to GitHub and the Gems registry.
- Publish the draft release in GitHub.
