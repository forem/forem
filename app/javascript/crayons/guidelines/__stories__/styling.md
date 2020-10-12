# Styling

If you ever end up writing your own CSS, it's worth to know several things.

## Mobile first approach

We try to write frontend code for mobile and then use media queries for bigger
breakpoints. You can read more about it in Responsiveness section.

## SCSS

We use SCSS as a CSS preprocessor. So you can use all the magic that SCSS
offers.

## CSS Variables

Even though we use SCSS, we prefer to use native CSS variables because they are
more flexible. You should be able to view all variables we have in
`app/assets/stylesheets/config/_variables.scss` file. Since this file is
imported everywhere, you should not need to import that by your own.

Fun fact: there's one exception to that: responsiveness breakpoints. Since you
can't use a CSS variables when defining a media query, this is the only case
when we use SCSS variables. It's just easier.

## Themes

Forem support multiple themes so you should always test your work against all
themes. We have a file with all color variables and each theme has its own too.

- Default theme: `app/assets/stylesheets/config/_colors.scss`

- Other themes (minimal, night, pink, hacker): `app/assets/stylesheets/themes`

## Import.scss

When you create a new SCSS file you may want to import one file at the top of
your new file: `app/assets/stylesheets/config/_import.scss` - it contains some
helpers as well as breakpoint variables I mentioned earlier.

## Folders

You can access all of the SCSS files in `app/assets/stylesheets` folder.

- `/base` - this folder contains some fundamental styling for layouts, resets
  and icons.

- `/components` - this folder contains separate SCSS file for each component we
  have... tags, buttons, forms, ...

- `/config` - this folder contains bunch of configuration files. These are worth
  explaining:

  - `_colors.scss` - I mentioned it couple lines above - it contains all color
    variables used in Crayons.

  - `_generator.scss` - it's basically a huge SCSS mixin generating ALL our
    utility classes.

  - `_import.scss` - it contains bunch of helpers for SCSS as well as media
    breakpoints variables.

  - `_variables.scss` - it contains all CSS native variables.

- `/themes` - this folder contains color declarations for other themes.

- Other folders and top level files are mostly legacy... :) We still use them,
  but slowly trying to move all the styling to appropriate Crayons-related
  files. Exceptions:

  - `crayons.scss` - this is one importing everything Crayons-related like
    variables, components styling, utility classes etc.

  - `views.scss` - this one contains views-specific styling. It is separated
    from Crayons to make Crayons library DEV agnostic.

  - `minimal.scss` - this one is actually one of the main stylesheets from
    pre-Crayons era. It imports everything basically :).
