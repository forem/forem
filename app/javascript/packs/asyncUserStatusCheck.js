import '@utilities/document_ready';

export async function asyncUserStatusCheck() {
  const indicator = ` <span data-testid="user-status" class="ml-3 c-indicator c-indicator--danger c-indicator--relaxed">Suspended</span>`;

  const profile = document.querySelector('.profile-header__details');

  if (profile && !profile.dataset.statusChecked) {
    await window
      .fetch(profile.dataset.url)
      .then((res) => res.json())
      .then((data) => {
        profile.dataset.statusChecked = true;
        const { suspended } = data;
        if (suspended) {
          profile.querySelector('.js-username-container').innerHTML +=
            indicator;
        }
      });
  }
}

document.ready.then(() => {
  asyncUserStatusCheck();
});
