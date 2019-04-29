---
title: Theming Model
---

# Theming Model

DEV.to supports different themes such as Normal, Dark, Pink. These themes are powered by [css custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties) which are loaded at runtime by javascript via `layouts/_user_config.html.erb`.

```
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

Within scss files located at `/app/assets/stylesheets` you will see `var` which will call these css custom properties. If a css custom property is not defined `var` will fall back on the second parameter provided which are css variables defined in `app/assets/stylesheets/variables.scss`

```
    color: var(--theme-color, $black);
```
