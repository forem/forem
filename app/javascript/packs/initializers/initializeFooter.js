export function toggleFooterVisibility() {
  const footer = document.querySelector('#footer');
  if (!footer) {
    return;
  }
  if (window.location.pathname === '/') {
    footer.style.display = 'none';
  } else {
    footer.style.display = 'block';
  }
}
// To ensure correct footer visibility even when opening a child page in a new tab,
// we add a DOMContentLoaded event listener, which calls toggleFooterVisibility
// after the entire page, including the footer, is fully loaded.
document.addEventListener('DOMContentLoaded', () => {
  toggleFooterVisibility();
});
toggleFooterVisibility();
