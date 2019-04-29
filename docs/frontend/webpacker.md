---
title: Webpacker
---

# Webpacker

DEV.to has two javascript codebases. One is located at
`/app/javascripts` and this is plain javascript being served using `spockets`

The other codebase is located at `/app/javascript` which is for preact
components and is served via `webpack` which is integrated into the
Rails app using `Webpacker`

There is a packs directory `/app/javascript/packs` where you can create
new pack files.

Since DEV.to is not an SPA (Single Page Application)
preact apps are mounted as needed by including the pack file in the erb
files. eg

```
<%= javascript_pack_tag "webShare", defer: true %>
```

This pack would correspond with

```
app/javascripts/packs/webShare.js
```
