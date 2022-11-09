/* global Honeybadger */

function initializeHamburgerMenu() {
  fetch('/async_info/hamburger')
    .then((response) => {
      if (response.ok) {
        return response.text();
      }
      
      throw new Error(`HTTP error! Status: ${response.status}`);
    }).then((html) => {
      console.log("RES: ", html);
      document.getElementById("hamburger-menu-placeholder").replaceWith(html);
    }).catch((error) => {
      Honeybadger.notify(error);
    });
}
