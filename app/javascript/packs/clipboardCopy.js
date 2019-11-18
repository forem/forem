import clipboard from 'clipboard-polyfill';

window.clipboard = clipboard;

window.WebComponents.waitFor(() => {
  import('@github/clipboard-copy-element');
});
