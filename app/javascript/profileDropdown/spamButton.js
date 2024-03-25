/* global userData */
/* eslint-disable no-alert, import/order */
import { request } from '@utilities/http';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

function addSpamButton(spamButton) {
  const { profileUserId, profileUserName } = spamButton.dataset;

  let isUserSpam = spamButton.dataset.isUserSpam === 'true';

  function toggleSpam() {
    const confirm = window.confirm(
      isUserSpam
        ? 'Are you sure you want to remove the spam role from this user? This will make all of their posts and comments visible again, and regain their access to new posts'
        : 'Are you sure you want to add the spam role to this user? This will hide all of their posts and comments and restrict their access to create new posts and comments',
    );

    if (confirm) {
      request(`/users/${profileUserId}/spam`, {
        method: isUserSpam ? 'DELETE' : 'PUT',
      })
        .then((response) => {
          if (response.ok) {
            isUserSpam = !isUserSpam;
            spamButton.innerHTML = isUserSpam ? `Set ${profileUserName} in Good standing` :  `Mark ${profileUserName} as Spam`;
          }
        })
        .catch((e) => {
          Honeybadger.notify(
            isUserSpam ? 'Unable to remove spam role from user' : 'Unable to mark user as spam',
            profileUserId,
          );
          window.alert(`Something went wrong: ${e}`);
        });
    }
  }

  spamButton.addEventListener('click', toggleSpam);
}

/**
 * Adds a spam button visible only to admin users on profile pages.
 * @function initSpam
 * @returns {(void|undefined)} This function has no useable return value.
 */

export function initSpam() {
  const spamButton = document.getElementById(
    'user-profile-dropdownmenu-spam-button',
  );

  if (!spamButton) {
    // button not always present when this is called
    return;
  }

  getUserDataAndCsrfToken().then(() => {
    const user = userData();
    if (!user || !user.admin) {
      spamButton.remove();
      return;
    }
    addSpamButton(spamButton);
  });
}
/* eslint-enable no-alert */
