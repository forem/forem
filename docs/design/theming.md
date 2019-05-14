---
title: Theming Guidelines
---

# Theming Guidelines

DEV supports different themes such as Default, Night, Pink.

You can switch the theme at <http://localhost:3000/settings/misc> in the "Style Customization" section.

These themes are powered by [CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties), loaded at runtime by Javascript via `layouts/_user_config.html.erb`.

An example of how it works:

```javascript
<script>
  try {
    var bodyClass = localStorage.getItem('config_body_class');
    document.body.className = bodyClass;
    if (bodyClass.includes('night-theme')) {
            document.getElementById('body-styles').innerHTML = '<style>\
              :root {\
        --theme-background: #0d1219;\
        --theme-color: #fff;\
        --theme-logo-background: #0a0a0a;\
        --theme-logo-color: #fff;\
        --theme-anchor-color: #17a1f6;\
        --theme-secondary-color: #cedae2;\
        --theme-top-bar-background: #1c2938;\
        --theme-top-bar-background-hover: #27384c;\
        --theme-top-bar-color: #fff;\
        --theme-top-bar-search-background: #424a54;\
        --theme-top-bar-search-color: #fff;\
        --theme-top-bar-write-background: #00af81;\
        --theme-top-bar-write-color: #fff;\
        --theme-container-background: #141f2d;\
        --theme-container-accent-background: #202c3d;\
        --theme-container-background-hover: #37475c;\
        --theme-gradient-background: linear-gradient(to right, #293d56 8%, #282833 18%, #293d56 33%);\
        --theme-container-color: #fff;\
        --theme-container-box-shadow: none;\
        --theme-container-border: 1px solid #141d26;\
        --theme-social-icon-invert: invert(100)</style>'
```

Within SCSS files located at `app/assets/stylesheets` you can use `var()` statements, which will call these CSS custom properties. If a CSS custom property is not defined `var()` will fall back on the second parameter provided, which can be a SCSS variable defined in `app/assets/stylesheets/variables.scss`.

An example of how to use `var()`:

```scss
div {
  color: var(--theme-color, $black);
}
```

Note that fallback values aren't used to fix the browser compatibility. If the browser doesn't support CSS custom Properties, the fallback value won't help. To prevent this issue on older browsers, we need to write our styles like this:

```scss
div {
  color: $black;
  color: var(--theme-color, $black);
}
```

This can be too much work and browser fallback can be forgotten. For a better developer experience, you should use the 2 mixins defined in `app/assets/stylesheets/_mixins.scss` called `themeable` and `themeable-important`. They take 3 arguments. The first argument is the CSS property like `color` or `background`, the second argument is the CSS custom property name (without `--`) like `theme-color` and the third argument is the CSS value like `$black` or `white`.

Make sure to import the mixin in your SCSS file and use it like this:

```scss
div {
  @include themeable(
    color, 
    theme-color, 
    $black
  );
}
```

`themeable-important` is used when a CSS variable requires `!important` as a postfix of the CSS property's value where the CSS variable is being used. You can use it the same way you would use `themeable` mixin but you should avoid `!important` if possible.
