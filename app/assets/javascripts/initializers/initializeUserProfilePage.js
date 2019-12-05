'use strict';

function initializeUserProfilePage() {
  const profileDropdownDiv = document.getElementsByClassName("profile-dropdown")[0];
  if (profileDropdownDiv) {
    const currentUser = userData();
    if (currentUser && (currentUser.username === profileDropdownDiv.dataset.username)) {
      profileDropdownDiv.hidden = true;
    }
    else {
      profileDropdownDiv.hidden = false;
      const userProfileDropdownButton = document.getElementById('user-profile-dropdown');
      if (userProfileDropdownButton) {
        const userProfileDropdownMenu = document.getElementById('user-profile-dropdownmenu');
        userProfileDropdownButton.addEventListener('click', () => {
          userProfileDropdownMenu.classList.toggle('showing');
        });
      }
    }
  }
}
