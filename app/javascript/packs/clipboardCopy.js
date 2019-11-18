HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

document.ready.then(() => {
  if (
    !window.clipboard &&
    !window.Clipboard &&
    !navigator.clipboard &&
    !navigator.Clipboard
  ) {
    window.clipboard = import('clipboard-polyfill');
  }
});

window.WebComponents.waitFor(() => {
  import('@github/clipboard-copy-element');
});
