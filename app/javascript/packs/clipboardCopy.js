document.addEventListener('DOMContentLoaded', () => {
  const waitingForOnboarding = setInterval(() => {
    if (window.WebComponents) {
      window.WebComponents.waitFor(() => {
        import('@github/clipboard-copy-element');
      });
      clearInterval(waitingForOnboarding);
    }
  }, 500);
});
