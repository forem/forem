/* global userData */
/* eslint-disable no-alert */
/**
 * Adds a flag button visible only to trusted users on profile pages.
 * @function initFlag
 * @returns {(void|undefined)} This function has no useable return value.
 */
export function initFlag() {
  const flagButton = document.getElementById(
    'user-profile-dropdownmenu-flag-button',
  );

  if (!flagButton) {
    // button not always present when this is called
    return;
  }

  const user = userData();
  if (!user) {
    return;
  }

  const { profileUserId, profileUserName } = flagButton.dataset;
  let isUserFlagged = flagButton.dataset.isUserFlagged === 'true';
  const trustedOrAdmin = user.trusted || user.admin;

  if (!trustedOrAdmin || user.id === parseInt(profileUserId, 10)) {
    flagButton.remove();
  }

  function flag() {
    const confirmFlag = window.confirm(
      isUserFlagged
        ? 'Are you sure you want to unflag this person? This will make all of their posts visible again.'
        : 'Are you sure you want to flag this person? This will make all of their posts less visible.',
    );

    if (confirmFlag) {
      fetch('/reactions', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': window.csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          reactable_type: 'User',
          category: 'vomit',
          reactable_id: profileUserId,
        }),
      })
        .then((response) => response.json())
        .then((response) => {
          if (response.result === 'create') {
            isUserFlagged = true;
            flagButton.innerHTML = `Unflag ${profileUserName}`;
          } else {
            isUserFlagged = false;
            flagButton.innerHTML = `Flag ${profileUserName}`;
          }
        })
        .catch((e) => window.alert(`Something went wrong: ${e}`));
    }
  }

  flagButton.addEventListener('click', flag);
}
/* eslint-enable no-alert */
