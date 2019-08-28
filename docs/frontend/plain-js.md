---
title: Javascript and Initializers
---

# Javascript and Initializers

DEV has two Javascript codebases.

One is located in the directory
`app/assets/javascripts` and contains plain Javascript (mostly ES5+) being served using [Sprockets](https://github.com/rails/sprockets-rails) which packages static assets.

The other one is managed by Webpacker and you can read more about [in its own guide](/frontend/webpacker).

This source code is not transpiled, only packaged and minified, and will be limited to whatever flavour of Javascript can run on user's web browser.

`app/assets/javascripts/application.js` contains the manifest Javascript file
which is included globally in the primary template, `app/views/layouts/application.html.erb`.

`application.js` automatically includes all JS files via the statement:

```erb
//= require_tree .
```

One JS file in particular, `app/assets/javascripts/initializePage.js.erb`, boostraps the majority of the functionality. You will notice, within this file, that major sections of the websites are bootstrapped, for example:

```javascript
initializeBaseTracking();
initializeTouchDevice();
initializeCommentsPage();
initEditorResize();
initLeaveEditorWarning();
initializeArticleReactions();
initNotifications();
initializeSplitTestTracking();
```

All the "initializers" are in `/app/assets/javascripts/initializers`.
