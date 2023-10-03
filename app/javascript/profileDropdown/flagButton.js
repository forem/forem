/* global userData */
/* eslint-disable no-alert, import/order */
import { request } from '@utilities/http';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

function addFlagUserBehavior(flagButton) {
  const { profileUserId, profileUserName } = flagButton.dataset;

  let isUserFlagged = flagButton.dataset.isUserFlagged === 'true';

  function flag() {
    const confirmFlag = window.confirm(
      isUserFlagged
        ? 'Ви дійсно хочете зняти позначку шадоубану з цієї людини? Це зробить всі її публікації знову видимими'
        : 'Ви впевнені, що хочете позначити цю людину як шкідливу чи нецікаву для спільноти? Це зробить всі її дописи менш помітними.',
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
