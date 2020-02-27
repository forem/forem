---
title: Styles
---

# Styles

The majority of the CSS in the application is written in
[SASS](https://sass-lang.com/). There are a few places in the code base that
have style blocks in ERB templates, for inlining critical CSS (good). There are
also some styles that live in ERB templates that are not critical CSS (bad).
That is a bit of refactoring that needs to be done. PRs welcome!

Important files when working with SASS in the project:

- variables:
  [/app/assets/stylesheets/variables.scss](https://github.com/thepracticaldev/dev.to/blob/master/app/assets/stylesheets/variables.scss)
- mixins:
  [/app/assets/stylesheets/\_mixins.scss](https://github.com/thepracticaldev/dev.to/blob/master/app/assets/stylesheets/_mixins.scss)

SASS is compiled and served using
[Sprockets](https://github.com/rails/sprockets-rails) which packages static
assets in Rails.

For more about branding, theming or design in general in regards to DEV, refer
to the [Design Guide](/design) documentation.

# Significant "shell" CSS and HTML changes and deployment

We use serviceworkers to cache the base application shell in user browsers so
that we only have to serve partial pages.

This means that when we make _substantial_ updates to core styles that affect
all pages or affect the home page in a big way, we need to increment the
`impactful_shell_version` number in `ApplicationHelper`. Small adjustments, even
if they result in slight design regressions do not need this number incremented
because as soon as users visit the site they will get a fresh shell download in
the background.

Because shell incrementation forces a reload of the current page when a visitor
first comes to the site after it is deployed has a negative impact on their
experience, we should make an effort to not do this overly often and where
possible ship changes which are temporarily compatable with the old and new
designs.

We may eventually be able to come up with new and better ways to update the
cached shell.
