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
  [/app/assets/stylesheets/variables.scss](https://github.com/forem/forem/blob/main/app/assets/stylesheets/variables.scss)
- mixins:
  [/app/assets/stylesheets/\_mixins.scss](https://github.com/forem/forem/blob/main/app/assets/stylesheets/_mixins.scss)

SASS is compiled and served using
[Sprockets](https://github.com/rails/sprockets-rails) which packages static
assets in Rails.

For more about branding, theming or design in general in regards to Forem, refer
to the [Design Guide](/design) documentation.

## Crayons

Crayons is the design system used by Forem. A
[storybook](https://storybook.js.org/) listing the various elements is available
at https://storybook.forem.com/

You can also run it locally with the following command:

```
$ yarn storybook
```
