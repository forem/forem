document.addEventListener('DOMContentLoaded', () => {
  window.WebComponents.waitFor(() => {
    import('@github/clipboard-copy-element');
  });
});
