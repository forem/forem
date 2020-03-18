---
title: Dynamic Imports
---

# Dynamic Imports

[Dynamic imports](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import/#Dynamic_Imports)
are supported in all major browsers except for Edge
([EdgeHTML](https://en.wikipedia.org/wiki/EdgeHTML) version) and Internet
Explorer which are both unsupported browsers for DEV. They allow you to import
JavaScript dynamically instead of statically. Why is this important?
Performance.

Should you use them everywhere? No. They are a great tool when you need to load a
JavaScript module on the fly for functionality that is not needed immediately
for the page to be usable.

Here are a couple of examples of dynamic import usage on DEV:

- The
  [Onboarding flow](https://github.com/thepracticaldev/dev.to/blob/master/app/javascript/packs/Onboarding.jsx#L28).
- In
  [connect](https://github.com/thepracticaldev/dev.to/blob/master/app/javascript/chat/codeEditor.jsx#L11)
  (chat)

DEV uses [webpacker](frontend/webpacker) (webpack), so what webpack will do is
create separate bundles for code that is dynamically imported. So not only do we
end up loading code only when we need it, we also end up with smaller bundle
sizes in the frontend.

For a great deep dive into dynamic imports, there is a great article from
community member [@goenning](https://dev.to/goenning) about dynamic import
usage,
[How we reduced our initial JS/CSS size by 67%](https://dev.to/goenning/how-we-reduced-our-initial-jscss-size-by-67-3ac0).
