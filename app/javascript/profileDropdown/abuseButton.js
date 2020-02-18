/* eslint-disable no-alert */

export default function initAbuseButton() {
  // eslint-disable-next-line no-undef
  const user = userData();

  const abuseButton = document.getElementById(
    'user-profile-dropdownmenu-abuse-button',
  );

  const { profileUserId } = abuseButton.dataset;

  if (user.trusted) {
    abuseButton.style.display = 'block';
  }

  function isFlagged() {
    return abuseButton.textContent === 'Remove Abuse Flag';
  }

  function flagAsAbusive() {
    const confirm = isFlagged()
      ? true
      : window.confirm(`Are you sure you want to flag this account?`);
    if (confirm) {
      fetch(`/reactions`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': window.csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          reactable_id: profileUserId,
          category: 'vomit',
          reactable_type: 'User',
        }),
      })
        .then(response => response.json())
        .then(response => {
          if (response.result === 'create') {
            abuseButton.innerText = 'Remove Abuse Flag';
          } else if (response.result === 'destroy') {
            abuseButton.innerText = 'Flag as Abusive';
          }
        })
        .catch(e => {
          window.alert(
            `Something went wrong: ${e}. -- Please refresh the page to try again.`,
          );
        });
    }
  }

  abuseButton.addEventListener('click', flagAsAbusive);
}
