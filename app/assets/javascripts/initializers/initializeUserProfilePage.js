'use strict';

function initializeUserProfilePage() {
  if (document.getElementById('user-profile-dropdown')) {
    document.getElementById('user-profile-dropdown').onclick = () => {
      document
        .getElementById('user-profile-dropdownmenu')
        .classList.toggle('showing');
    };
  }
}
