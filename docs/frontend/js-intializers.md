---
title: Plain Javascript and Intializers
---

# Plain Javascript and JS Intializers

DEV.to has two javascript codebases. One is located at
`/app/javascripts` and this is plain javascript being served using [spockets](https://github.com/rails/sprockets-rails)

The plain javascript codebase is not transpiled and will be limited to
whatever flavour of javascript provided by the end-user's
web-browser

`app/javascripts/application.js` is primary packaged javascript file
which should be included in the primary template located within
`app/layouts`. `application.js` automatically includes all javascript
files via:

```
//= require_tree .
```

One javascript file it loads is `initializePage.js.erb` which boostraps
the majority of functionality. You will see wtihin this file it manually
loads multiple files:

```
  initializeBaseTracking();
  initializeTouchDevice();
  initializeCommentsPage();
  initEditorResize();
  initLeaveEditorWarning();
  initializeArticleReactions();
  initNotifications();
  initializeSplitTestTracking();
```

Theses files are located at `/app/assets/javascripts/intializers`
