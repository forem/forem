## Submitting a Pull Request

0. Read our [Code of Conduct](CODE_OF_CONDUCT.md).
1. Check out [Hacking on Octokit](README.md#hacking-on-octokitrb) in the
   README for bootstrapping the project for local development.
2. [Fork the repository.][fork]
3. [Create a topic branch.][branch]
4. Add specs for your unimplemented feature or bug fix.
5. Run `script/test`. If your specs pass, return to step 3.
6. Implement your feature or bug fix.
7. Run `script/test`. If your specs fail, return to step 5.
8. Run `open coverage/index.html`. If your changes are not completely covered
   by your tests, return to step 4.
9. Add documentation for your feature or bug fix.
10. Run `bundle exec rake doc:yard`. If your changes are not 100% documented, go
   back to step 8.
11. Add, commit, and push your changes. For documentation-only fixes, please
    add "[ci skip]" to your commit message to avoid needless CI builds.
12. [Submit a pull request.][pr]

[fork]: https://help.github.com/articles/fork-a-repo
[branch]: https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/
[pr]: https://help.github.com/articles/using-pull-requests
