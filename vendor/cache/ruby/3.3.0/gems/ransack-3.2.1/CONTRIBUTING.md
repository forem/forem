# Contributing to Ransack

Please take a moment to review this document to make contributing easy and
effective for everyone involved!

Ransack is an open source project and we encourage contributions.

Please do not use the issue tracker for personal support requests. Stack
Overflow is a better place for that where a wider community can help you!

## Filing an issue

Good issue reports are extremely helpful!  Please only open an issue if a bug
is caused by Ransack, is new (has not already been reported), and can be
reproduced from the information you provide.

Steps:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   `main` branch in the repository.

3. **Isolate the real problem** &mdash; make sure the issue is really a bug in
   Ransack and not in your code or another gem.

4. **Report the issue** by providing the link to a self-contained
   gist like [this](https://github.com/activerecord-hackery/ransack/blob/main/bug_report_templates/test-ransack-scope-and-column-same-name.rb) or
   [this](https://github.com/activerecord-hackery/ransack/blob/main/bug_report_templates/test-ransacker-arel-present-predicate.rb). Please use
   these code examples as a bug-report template for your Ransack issue!

If you do not provide a self-contained gist and would like your issue to be reviewed, do provide at a minimum:

* A comprehensive list of steps to reproduce the issue, or even better, a
  passing/failing test spec.
* Whether you are using Ransack through another gem like ActiveAdmin,
  SimpleForm, etc.
* The versions of Ruby, Rails, Ransack and the database.
* Any relevant stack traces ("Full trace" preferred).

Issues filed without the above information or that remain open without activity
for 14 days will be closed. They can be re-opened if actionable information to reproduce the issue is provided.

## Pull requests

We gladly accept pull requests to fix bugs and, in some circumstances, add new
features to Ransack. If you'd like to contribute and wonder what would be
helpful, simply run a search for "FIXME" and "TODO" on the codebase :smiley:

If you're new to contributing to open source, welcome! It can seem scary, so
here is a [great blog post to help you get started]
(http://robots.thoughtbot.com/8-new-steps-for-fixing-other-peoples-code),
step by step.

Before issuing a pull request, please make sure that all specs are passing,
that any new features have test coverage, and that anything that breaks
backward compatibility has a very good reason for doing so.

Here's a quick guide:

1. Fork the repo.

2. Create a thoughtfully-named branch for your changes (`git checkout -b my-new-feature`).

3. Install the development dependencies by running `bundle install`.
   To install rails other than latest (set in Gemfile): `RAILS='6-1-stable' bundle install`

4. Begin by running the tests. We only take pull requests with passing tests,
   and it's great to know that you have a clean slate:

        $ bundle exec rake spec

   The test suite runs by default with SQLite3. To run the test suite with PostgreSQL or MySQL, use:

        $ DB=pg bundle exec rake spec (`DB=postgres` & `DB=postgresql` work too)
        $ DB=mysql bundle exec rake spec

   For Postgres and MySQL, databases are expected to exist, called 'ransack'. To create use these commands (assuming OS X and Homebrew):

   ### Postgres
       $ createdb ransack 

   ### MySQL
       $ mysql -u root
       mysql> create database ransack;     

   The test suite runs by default

   To run only the tests in a particular file: `bundle exec rspec <path/to/filename>`

        $ bundle exec rspec spec/ransack/search_spec.rb

   To run a single test in that file: `bundle exec rspec <path/to/filename> -e "test name"`

        $ bundle exec rspec spec/ransack/search_spec.rb -e "accepts a context option"

5. Hack away! Please use Ruby features that are compatible down to Ruby 2.3.
   Since version 2.3.1, Ransack no longer maintains Ruby 2.2 compatibility.

6. Add tests for your changes. Only refactoring and documentation changes
   require no new tests. If you are adding functionality or fixing a bug, we
   need a test!

7. Make the tests pass.

8. Update the Change Log. If you are adding new functionality, document it in
   the README.

9. Make sure git knows your name and email address in your `~/.gitconfig` file:

        $ git config --global user.name "Your Name"
        $ git config --global user.email "contributor@example.com"

10. Commit your changes (`git commit -am 'Add feature/fix bug/improve docs'`).
    If your pull request only contains documentation changes, please remember
    to add `[skip ci]` to the beginning of your commit message so the CI
    test suite doesn't :runner: needlessly.

11. If necessary, rebase your commits into logical chunks, without errors. To
   interactively rebase and cherry-pick from, say, the last 10 commits:
   `git rebase -i HEAD~10`, then `git push -f`.

12. Push the branch up to your fork on GitHub
   (`git push origin my-new-feature`) and from GitHub submit a pull request to
   Ransack's `main` branch.

At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within three business days (and, typically, one business
day). We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Include tests that fail without your code, and pass with it.
* Update the README, the change log, the wiki documentation... anything that is
  affected by your contribution.
* Use idiomatic Ruby and follow the syntax conventions below.

Syntax:

* Indent with two spaces, no tabs.
* 80 characters per line.
* No trailing whitespace. Blank lines should not have any space.
* Prefer `&&`/`||` over `and`/`or`.
* `MyClass.my_method(my_arg)` not `my_method( my_arg )` or `my_method my_arg`.
* `a = b` and not `a=b`.
* `a_method { |block| ... }` and not `a_method { | block | ... }` or
`a_method{|block| ...}`.
* Prefer simplicity, readability, and maintainability over terseness.
* Follow the conventions you see used in the code already.

And in case we didn't emphasize it enough: We love tests!
