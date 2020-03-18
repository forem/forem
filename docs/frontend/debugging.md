---
title: Debugging
---

# Debugging

## In Browser

Browsers ship with their own developer tools. These are amazing tools to help
you debug your web application. Consider learning how to use them.

- [Chrome Developer Tools](https://developers.google.com/web/tools/chrome-devtools)
- [Firefox Developer Tools](https://developer.mozilla.org/en-US/docs/Tools)
- [Safari Developer Tools](https://support.apple.com/en-ca/guide/safari/sfri20948/mac)

## Visual Studio Code

[Visual Studio Code](https://code.visualstudio.com) (VS Code) is a popular
editor that allows you to debug many languages including JavaScript. Thanks to
remote debugging technologies, we can debug our frontend code in VS Code. When
you clone the DEV repository and open the project in VS Code, you will be
prompted to install recommended extensions which include the
[Chrome Debugger](https://code.visualstudio.com/blogs/2016/02/23/introducing-chrome-debugger-for-vs-code)
and the
[Edge Debugger](https://marketplace.visualstudio.com/items?itemName=msjsdiag.debugger-for-edge).

Setup:

- Refer to the respective debugger extension documentation above to ensure that
  your browser is running with remote debugging enabled.
- Once you have your local installation of DEV running, you can attach to either
  the Chrome or Edge Debugger.

  ![Launch menu for debugger in VS Code](/vscode_launch_debugger.png 'Launch
menu for debugger in VS Code')

- From there you can do all the usual stuff that you would do while debugging
  JavaScript in the browser: setting breakpoints, setting
  [logpoints](https://code.visualstudio.com/docs/editor/debugging#_logpoints),
  watches etc.

## Where is My Editor Debug Configuration?

If you do not see your editor here, consider contributing to the documentation.
😉

## Preact Developer Tools

Preact has their
[own developer tools](https://preactjs.github.io/preact-devtools/) in the form
of a browser extension. These tools are currently supported for Preact version
10.x and up.

DEV currently uses Preact 8.x so the Preact developer tools are not an option,
however Preact 8.x+ is compatible with the React developer tools extension which
is available for Chrome and Firefox.
