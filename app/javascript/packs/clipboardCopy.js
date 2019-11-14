document.addEventListener('DOMContentLoaded', () => {
  window.WebComponents.waitFor(() => {
    window.clipboard = require('clipboard-polyfill');
    import('@github/clipboard-copy-element');
  });
});
