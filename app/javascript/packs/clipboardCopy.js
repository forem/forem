HTMLDocument.prototype.ready = new Promise((resolve) => {
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
    import('clipboard-polyfill').then((module) => {
      window.clipboard = module;
    });
  }
});

// import('@github/clipboard-copy-element');
// Temporarily removed due to problems
