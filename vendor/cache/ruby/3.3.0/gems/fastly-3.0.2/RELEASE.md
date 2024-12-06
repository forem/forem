**Release Process**

1. Sign up for an account on Ruby Gems (https://rubygems.org/sign_up)
2. Go to the `#app-eng-backends` channel and get added to the ruby gem (https://rubygems.org/gems/fastly)
3. Merge PR after CI passes
4. Open new PR to update `CHANGELOG.md`
5. Merge `CHANGELOG.md` PR
6. Rebase latest remote master branch locally (`git pull --rebase origin master`).
7. Tag a new release (`git tag vX.Y.Z && git push origin vX.Y.Z`)
8. Copy and paste `CHANGELOG.md` into the draft release
9. Publish draft release
10. Publish the gem to RubyGems.org (you will need your username and password on Ruby Gems)

- generate a new gem spec file with the new version `gem build fastly.gemspec`
- update RubyGems.org `gem push fastly-{VERSION}.gem`
