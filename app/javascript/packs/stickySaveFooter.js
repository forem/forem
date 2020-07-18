const form = document.querySelector('.edit_user');

form.addEventListener('change', () => {
    const saveFooter = document.querySelector('#save-footer');
    saveFooter.classList.add('sticky-save-footer');
});
  