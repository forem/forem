/* eslint-disable no-alert */

export function initFlag() {
  const flagButton = document.getElementById(
    'user-profile-dropdownmenu-flag-button',
  );
  if (!flagButton) {
    // button not always present when this is called
    return;
  }
  const { profileUserId } = flagButton.dataset;

  function flag() {
    const confirmFlag = window.confirm(
      `Are you sure you want to flag this person? This will make all of their posts less visible and cannot be undone.`,
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
            window.alert('All posts by this author will be less visible.');
          } else if (response.result === null) {
            window.alert(
              "It seems you've already reduced the visibility of this author's posts.",
            );
          }
        })
        .catch((e) => window.alert(`Something went wrong: ${e}`));
    }
  }

  flagButton.addEventListener('click', flag);

  /* eslint-disable-next-line no-undef */
  const user = userData();
  if (!user) {
    return;
  }

  if (user.id === parseInt(profileUserId, 10)) {
    flagButton.style.display = 'none';
  }
}

/* eslint-enable no-alert */
