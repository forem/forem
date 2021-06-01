'use strict';

function initializeRegistration() {
  togglePasswordVisibility();
}

function togglePasswordVisibility() {
  let passwordField = document.getElementsByClassName('js-password')[0];

  const type = passwordField.type === 'password' ? 'text' : 'password';
  passwordField.type = type;
  // change the icon as well
}
