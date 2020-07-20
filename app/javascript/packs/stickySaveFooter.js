const form = document.querySelector('.edit_user');

form.addEventListener('change', () => {
    const saveFooter = document.getElementsByClassName('save-footer');
    saveFooter && saveFooter[0] && saveFooter[0].classList.add('sticky-save-footer');
});
