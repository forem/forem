---
title: Webpacker
---

# Webpacker

DEV has two Javascript codebases.

One contains plain Javascript and you can read about [in its own guide](/frontend/plain-js).

The other one is managed by [Webpacker](https://github.com/rails/webpacker) and it's located inside `/app/javascripts`, written using ES6+.

Currently it's mainly used for Preact components, served via `webpack` which is integrated into the Rails app using `Webpacker`.

There is a packs directory `/app/javascript/packs` where you can create
new "pack" files. Pack files are initializers for Webpacker.

Since DEV is not a Single Page Application (SPA), Preact components are mounted as needed by including the pack file in the view files.

For example:

```erb
<%= javascript_pack_tag "webShare", defer: true %>
```

The include statement corresponds to the pack `app/javascripts/packs/webShare.js`
