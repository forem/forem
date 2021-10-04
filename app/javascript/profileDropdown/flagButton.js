/* global userData */
/* eslint-disable no-alert, import/order */
import { request } from '@utilities/http';
import { i18next } from '@utilities/locale';
import { getUserDataAndCsrfToken } from '../chat/util';

function addFlagUserBehavior(flagButton) {
  const { profileUserId, profileUserName } = flagButton.dataset;

  let isUserFlagged = flagButton.dataset.isUserFlagged === 'true';

  function flag() {
    const confirmFlag = window.confirm(
      isUserFlagged
        ? i18next.t('profile.to_unflag')
        : i18next.t('profile.to_flag'),
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
            flagButton.innerHTML = i18next.t('profile.unflag', {
              name: profileUserName,
            });
          } else {
            isUserFlagged = false;
            flagButton.innerHTML = i18next.t('profile.flag', {
              name: profileUserName,
            });
          }
        })
        .catch((e) => {
          Honeybadger.notify(
            isUserFlagged ? 'Unable to unflag user' : 'Unable to flag user',
            profileUserId,
          );
          window.alert(i18next.t('errors.went', { error: e }));
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
