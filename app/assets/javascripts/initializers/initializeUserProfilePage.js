'use strict';

function initializeUserProfilePage() {
  const profileDropdownDiv = document.getElementsByClassName("profile-dropdown")[0];
  if (profileDropdownDiv) {
    const currentUser = userData();
    const profileUser = profileDropdownDiv.getAttribute('data-username');
    if (currentUser.username === profileUser) {
      profileDropdownDiv.hidden = true;
    }
    else {
      profileDropdownDiv.hidden = false;
      const userProfileDropdownButton = document.getElementById('user-profile-dropdown');
      if (userProfileDropdownButton) {
        const userProfileDropdownMenu = document.getElementById('user-profile-dropdownmenu');
        userProfileDropdownButton.addEventListener('click', (e) => {
          userProfileDropdownMenu.classList.toggle('showing');
        });
      }
    }
  }
}
