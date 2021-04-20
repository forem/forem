---
title: Manual Tests
---

# Manual Tests

We try to automate as much as possible, but particularly for frontend changes it
is usually necessary to verify work with a manual test. When manually testing a
feature, it's useful to check:

- Does the UI look consistent across different desktop browsers?
- Is the UI optimised for a mobile layout?
- Does the feature behave consistently across desktop and mobile browsers?
- Is the feature accessible? (See the
  [Accessibility testing docs](/tests/accessibility-tests))

## Tips for testing on mobile

For features involving touch interactions it becomes more important to test on
actual mobile devices, rather than using the browser dev-tools device simulator.
There can be some platform-specific differences in how these touch events are
handled and it's useful to make sure a feature is checked on both android and
iOS.

One way to run your development code on your own mobile device is to use
[ngrok](https://ngrok.com/). ngrok is a free tool that allows you to access your
`localhost:3000` via a standard URL. To use it:

- Follow [ngrok's instructions](https://ngrok.com/) to download/install the tool
  (there is a free tier)
- Run `ngrok http 3000` in your terminal
- Copy the URL given in response (e.g. `xxxxxxxxx.ngrok.io`) and add it to your
  `.env` file's `APP_DOMAIN` value (replacing `localhost:3000`)
- Start the app via `bin/startup` as usual
- Visit the ngrok URL on your mobile (to save copying the text, you could use a
  [QR code generator](https://www.qr-code-generator.com/free-generator/) on your
  desktop browser so you only need to point your camera at the screen)
