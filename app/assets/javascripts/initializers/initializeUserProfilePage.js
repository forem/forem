'use strict';

function initializeUserProfilePage() {
  if(document.querySelector('.profile-dropdown')){
    var profileDropdownDiv = document.querySelector('.profile-dropdown');
    var currentUser = userData();
    var profileUser = JSON.parse(profileDropdownDiv.getAttribute('data-info'));

    if(currentUser.username == profileUser.username){
      profileDropdownDiv.hidden = true;
    }
    else{
      profileDropdownDiv.hidden = false;
      if (document.getElementById('user-profile-dropdown')) {
        document.getElementById('user-profile-dropdown').onclick = () => {
          document
            .getElementById('user-profile-dropdownmenu')
            .classList.toggle('showing');
        };
      }
    }
  }
}
