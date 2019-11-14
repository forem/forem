window.clipboard = require('clipboard-polyfill');

window.WebComponents.waitFor(() => {
  import('@github/clipboard-copy-element');
});
