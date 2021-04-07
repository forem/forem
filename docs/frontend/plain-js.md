---
title: JavaScript and Initializers
---

# JavaScript and Initializers

Forem has two JavaScript codebases.

One is located in the directory `app/assets/javascripts` and contains plain
JavaScript (mostly ES5+) being served using
[Sprockets](https://github.com/rails/sprockets-rails) which packages static
assets.

Webpacker manages the other one,
[which you can read more about in this guide](/frontend/webpacker).

This source code is not transpiled, only packaged and minified, and will be
limited to whatever flavor of JavaScript can run on the user's web browser.

`app/assets/javascripts/application.js` contains the manifest JavaScript file
which is included globally in the primary template,
`app/views/layouts/application.html.erb`.

`application.js` automatically includes all JS files via the statement:

```erb
//= require_tree .
```

One JS file in particular, `app/assets/javascripts/initializePage.js`,
bootstraps the majority of the functionality. You will notice, within this file,
that major sections of the websites are bootstrapped, for example:

```javascript
initializeBaseTracking();
initializeCommentsPage();
initEditorResize();
initLeaveEditorWarning();
initializeArticleReactions();
initNotifications();
initializeSplitTestTracking();
```

All the "initializers" are in `/app/assets/javascripts/initializers`.
