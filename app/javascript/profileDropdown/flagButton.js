/* global userData */
/* eslint-disable no-alert, import/order */
import { request } from '@utilities/http';
import { getUserDataAndCsrfToken } from '../chat/util';

function addFlagUserBehavior(flagButton) {
  const { profileUserId, profileUserName } = flagButton.dataset;

  let isUserFlagged = flagButton.dataset.isUserFlagged === 'true';

  function flag() {
    const confirmFlag = window.confirm(
      isUserFlagged
        ? 'Are you sure you want to unflag this person? This will make all of their posts visible again.'
        : 'Are you sure you want to flag this person? This will make all of their posts less visible.',
    );

    if (confirmFlag) {
      request('/reactions', {
        method: 'POST',
        body: {
          reactable_type: 'User',
          category: 'vomit',
          reactable_id: profileUserId,
        },
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
        .catch((e) => {
          Honeybadger.notify(
            isUserFlagged ? 'Unable to unflag user' : 'Unable to flag user',
            profileUserId,
          );
          window.alert(`Something went wrong: ${e}`);
        });
    }
  }

  flagButton.addEventListener('click', flag);
}

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

  getUserDataAndCsrfToken().then(() => {
    const user = userData();
    if (!user) {
      flagButton.remove();
      return;
    }

    const trustedOrAdmin = user.trusted || user.admin;
    const { profileUserId } = flagButton.dataset;

    if (!trustedOrAdmin || user.id === parseInt(profileUserId, 10)) {
      flagButton.remove();
    }
    addFlagUserBehavior(flagButton);
  });
}
/* eslint-enable no-alert */
