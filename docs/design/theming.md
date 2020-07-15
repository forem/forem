---
title: Theming Guidelines
---

# Theming Guidelines

Forem supports different themes, such as Default, Night, Pink.

You can switch the theme at <http://localhost:3000/settings/ux> in the "Style
Customization" section.

These themes are powered by
[CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties),
loaded at runtime by JavaScript via `layouts/_user_config.html.erb`.

An example of how it works:

```javascript
try {
  const bodyClass = localStorage.getItem('config_body_class');

  if (bodyClass) {
    document.body.className = bodyClass;

    if (bodyClass.includes('night-theme')) {
      document.getElementById('body-styles').innerHTML = '<style><%= Rails.application.assets["themes/night.css"].to_s.squish.html_safe %></style>';
    } else if (bodyClass.includes('ten-x-hacker-theme')) {
      document.getElementById('body-styles').innerHTML = '<style><%= Rails.application.assets["themes/hacker.css"].to_s.squish.html_safe %></style>'
    } else if (bodyClass.includes('pink-theme')) {
      document.getElementById('body-styles').innerHTML = '<style><%= Rails.application.assets["themes/pink.css"].to_s.squish.html_safe %></style>'
    } else if(bodyClass.includes('minimal-light-theme')) {
      document.getElementById('body-styles').innerHTML = '<style><%= Rails.application.assets["themes/minimal.css"].to_s.squish.html_safe %></style>'
    }
    ...
```

Within SCSS files located at `app/assets/stylesheets` you can use `var()`
statements, which will call these CSS custom properties. If a CSS custom
property is not defined `var()` will fall back on the second parameter provided,
which can be a SCSS variable defined in `app/assets/stylesheets/variables.scss`.

An example of how to use `var()`:

```scss
div {
  color: var(--theme-color, $black);
}
```

Note that fallback values aren't used to fix the browser compatibility. If the
browser doesn't support CSS custom Properties, the fallback value won't help. To
prevent this issue on older browsers, we need to write our styles like this:

```scss
div {
  color: $black;
  color: var(--theme-color, $black);
}
```

This can be too much work and browser fallback can be forgotten. For a better
developer experience, you should use the two mixins defined in
`app/assets/stylesheets/_mixins.scss` called `themeable` and
`themeable-important`. They take three arguments. The first argument is the CSS
property like `color` or `background`, the second argument is the CSS custom
property name (without `--`) like `theme-color`, and the third argument is the
CSS value, i.e., `$black` or `white`.

Make sure to import the mixin in your SCSS file and use it like this:

```scss
div {
  @include themeable(color, theme-color, $black);
}
```

`themeable-important` is used when a CSS variable requires `!important` as a
postfix of the CSS property's value where the CSS variable is being used. You
can use it the same way you would use `themeable` mixin, but you should avoid
`!important` if possible.

# Other user config

In addition to themes, users can also directly configure their preferred fonts
and their nav bar preferences. The implementation of these is similar to themes.
