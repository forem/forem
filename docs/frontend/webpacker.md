---
title: Webpacker
---

# Webpacker

Forem has two JavaScript codebases.

One contains plain JavaScript,
[which you can read more about in this guide](/frontend/plain-js).

The other one is managed by [Webpacker](https://github.com/rails/webpacker), and
it's located inside `/app/javascript`, written using ES6+.

Currently, it's mainly used for Preact components, served via `webpack` which is
integrated into the Rails app using `Webpacker`.

There is a packs directory `/app/javascript/packs` where you can create new
"pack" files. Pack files are initializers for Webpacker.

Since Forem is not a Single Page Application (SPA), Preact components are
mounted as needed by including the pack file in the view files.

For example:

```erb
<%= javascript_packs_with_chunks_tag "webShare", defer: true %>
```

The include statement corresponds to the pack `app/javascript/packs/webShare.js`

If you have more than one webpacker pack on the page, you need to include it in
the same `javascript_packs_with_chunks_tag` call. The reason being is it avoids
loading split chunks multiple times.

```erb
<%= javascript_packs_with_chunks_tag "webShare", "someOtherPack", defer: true %>
```

## Webpack aliases

The project uses
[webpack aliases](https://webpack.js.org/configuration/resolve/#resolvealias).
The aliases used in the project can be found under `alias` in
https://github.com/forem/forem/blob/master/config/webpack/environment.js

## Additional Resources

For more information in regards to `javascript_packs_with_chunks_tag`, see
https://github.com/rails/webpacker/blob/main/lib/webpacker/helper.rb

Aside from the Webpacker repository, see also Ross Kaffenberger's
[visual guide to Webpacker](https://rossta.net/blog/visual-guide-to-webpacker.html).

If you're interested in bundles sizes and what's contained within them for a
production build, run `bin/bundleAnalyzer` from the command line.
