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

function updateUsername() {
  let nameField = document.getElementsByClassName(
    'js-forem-creator-signup-name',
  )[0].value;

  let username = document.getElementsByClassName(
    'js-forem-creator-signup-username',
  )[0];
  username.innerHTML = getUsername(nameField);

  let usernameField = document.getElementsByClassName(
    'js-forem-creator-signup-username-field',
  )[0];
  usernameField.value = getUsername(nameField);
}

// maybe add to helper
function getUsername(name) {
  return name.toLowerCase().replace(/[^a-zA-Z0-9]/g, '_');
}

function showUsernameField() {
  let usernameRow = document.getElementsByClassName('js-forem-creator-signup-username-row')[0];
  usernameRow.classList.remove('hidden');
}
