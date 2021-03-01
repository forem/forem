/* eslint-disable no-alert */
export function initFlag() {
  const flagButton = document.getElementById(
    'user-profile-dropdownmenu-flag-button',
  );
  if (!flagButton) {
    // button not always present when this is called
    return;
  }

  // userData() is a global function
  /* eslint-disable-next-line no-undef */
  const user = userData();
  if (!user) {
    return;
  }

  const { profileUserId } = flagButton.dataset;
  if (user.id === parseInt(profileUserId, 10)) {
    flagButton.style.display = 'none';
    return;
  }

  function flag() {
    const flagConfirm = window.confirm(``);

    if (flagConfirm) {
    }
  }

  flagButton.addEventListener('click', flag);
}

/* eslint-enable no-alert */
