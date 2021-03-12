/* eslint-disable no-alert */
export function initFlag() {
  const flagButton = document.getElementById(
    'user-profile-dropdownmenu-flag-button',
  );

  if (!flagButton) {
    // button not always present when this is called
    return;
  }

  /* eslint-disable-next-line no-undef */
  const user = userData();
  if (!user) {
    return;
  }

  const { profileUserId, profileUserName } = flagButton.dataset;
  let flagStatus = flagButton.dataset.flagStatus === 'true';

  if (user.id === parseInt(profileUserId, 10) || !user.trusted) {
    flagButton.remove();
  }

  function flag() {
    const confirmFlag = window.confirm(
      flagStatus
        ? "Are you sure you want to unflag this person? This will restore their posts' visibility."
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
            flagStatus = true;
            flagButton.innerHTML = `Unflag ${profileUserName}`;
            window.alert('All posts by this author will be less visible.');
          } else {
            flagStatus = false;
            flagButton.innerHTML = `Flag ${profileUserName}`;
            window.alert(
              'Unflagged the author, the visibility of their posts has been restored.',
            );
          }
        })
        .catch((e) => window.alert(`Something went wrong: ${e}`));
    }
  }

  flagButton.addEventListener('click', flag);
}
/* eslint-enable no-alert */
