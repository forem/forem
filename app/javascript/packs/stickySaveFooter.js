const form = document.querySelector('.sticky-footer-form');

form.addEventListener('change', () => {
  const saveFooter = document.getElementsByClassName('save-footer');
  saveFooter &&
    saveFooter[0] &&
    saveFooter[0].classList.add('sticky', 'bottom-0');
});
