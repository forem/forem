function setDefaultUsername(event) {
  if (
    document
      .getElementsByClassName('js-creator-signup-username-row')[0]
      .classList.contains('hidden')
  ) {
    const name = event.target.value;
    // It's the first user and so we can assume that this username is not taken.
    const usernameHint = createUsernameHint(name);
    setUsernameHint(usernameHint);
    setUsernameField(usernameHint);
    showHintRow();
  }
}

function createUsernameHint(name) {
  return name.toLowerCase().replace(/[^a-zA-Z0-9]/g, '_');
}

function showHintRow() {
  const hintRow = document.getElementsByClassName(
    'js-creator-signup-username-hint-row',
  )[0];
  hintRow.classList.remove('hidden');
}

function setUsernameHint(usernameHint) {
  const usernameHintDisplay = document.getElementsByClassName(
    'js-creator-signup-username-hint',
  )[0];
  usernameHintDisplay.innerHTML = usernameHint;
}

function setUsernameField(usernameHint) {
  const usernameField = document.getElementsByClassName(
    'js-creator-signup-username',
  )[0];
  usernameField.value = usernameHint;
}

function showUsernameField() {
  const usernameRow = document.getElementsByClassName(
    'js-creator-signup-username-row',
  )[0];
  usernameRow.classList.remove('hidden');
  hideHintRow();
}

function hideHintRow() {
  const hintRow = document.getElementsByClassName(
    'js-creator-signup-username-hint-row',
  )[0];
  hintRow.classList.add('hidden');
}

function togglePasswordVisibility() {
  const passwordField = document.getElementsByClassName('js-password')[0];
  const type = passwordField.type === 'password' ? 'text' : 'password';
  passwordField.type = type;

  toggleSVGelement(type);
}

function toggleSVGelement(type) {
  const eyeIcon = document.getElementsByClassName('js-eye')[0];
  const eyeOffIcon = document.getElementsByClassName('js-eye-off')[0];

  if (type === 'text') {
    eyeOffIcon.classList.remove('hidden');
    eyeIcon.classList.add('hidden');
  } else {
    eyeIcon.classList.remove('hidden');
    eyeOffIcon.classList.add('hidden');
  }
}

const visibility = document.getElementsByClassName(
  'js-creator-password-visibility',
)[0];
visibility.addEventListener('click', togglePasswordVisibility);

const name = document.getElementsByClassName('js-creator-signup-name')[0];
name.addEventListener('input', setDefaultUsername);

const editUsername = document.getElementsByClassName(
  'js-creator-edit-username',
)[0];
editUsername.addEventListener('click', showUsernameField);
