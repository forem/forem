'use strict';

function initializeRegistration() {
  togglePasswordVisibility();
}

function togglePasswordVisibility() {
  let passwordField = document.getElementsByClassName('js-password')[0];

  const type = passwordField.type === 'password' ? 'text' : 'password';
  passwordField.type = type;

  toggleSVGelement(type);
}

function toggleSVGelement(type) {
  let eyeIcon = document.getElementsByClassName('js-eye')[0];
  let eyeOffIcon = document.getElementsByClassName('js-eye-off')[0];

  if (type === 'text') {
    eyeOffIcon.classList.remove('hidden');
    eyeIcon.classList.add('hidden');
  } else {
    eyeIcon.classList.remove('hidden');
    eyeOffIcon.classList.add('hidden');
  }
}
