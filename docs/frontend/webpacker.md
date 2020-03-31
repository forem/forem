---
title: Webpacker
---

# Webpacker

DEV has two Javascript codebases.

One contains plain Javascript, you can read about it
[in its own guide](/frontend/plain-js).

The other one is managed by [Webpacker](https://github.com/rails/webpacker), and
it's located inside `/app/javascripts`, written using ES6+.

Currently, it's mainly used for Preact components, served via `webpack` which is
integrated into the Rails app using `Webpacker`.

There is a packs directory `/app/javascript/packs` where you can create new
"pack" files. Pack files are initializers for Webpacker.

Since DEV is not a Single Page Application (SPA), Preact components are mounted
as needed by including the pack file in the view files.

For example:

```erb
<%= javascript_packs_with_chunks_tag "webShare", defer: true %>
```

The include statement corresponds to the pack
`app/javascripts/packs/webShare.js`

If you have more than one webpacker pack on the page, you need to include it in
the same `javascript_packs_with_chunks_tag` call. The reason being is it avoids
loading split chunks multiple times.

```erb
<%= javascript_packs_with_chunks_tag "webShare", "someOtherPack", defer: true %>
```

For more information in regards to `javascript_packs_with_chunks_tag`, see
https://github.com/rails/webpacker/blob/master/lib/webpacker/helper.rb
