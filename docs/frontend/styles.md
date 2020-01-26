---
title: Styles
---

# Styles

The majority of the CSS in the application is written in
[SASS](https://sass-lang.com/). There are a few places in the code base that
have style blocks in ERB templates, but this is not the norm.

Important files when working with SASS in the project:

- variables:
  [/app/assets/stylesheets/variables.scss](https://github.com/thepracticaldev/dev.to/blob/master/app/assets/stylesheets/variables.scss)
- mixins:
  [/app/assets/stylesheets/_mixins.scss](https://github.com/thepracticaldev/dev.to/blob/master/app/assets/stylesheets/_mixins.scss)

SASS is compiled and served using
[Sprockets](https://github.com/rails/sprockets-rails) which packages static
assets in Rails.

For more about branding, theming or design in general in regards to DEV, refer
to the [Design Guide](/design) documentation.
