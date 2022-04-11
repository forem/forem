const form = document.getElementsByClassName('sticky-footer-form')[0];

form.addEventListener('change', () => {
  const saveFooter = document.getElementsByClassName('save-footer')[0];
  if (saveFooter) {
    saveFooter.classList.add('sticky', 'z-sticky', 'bottom-0');
  }
});
