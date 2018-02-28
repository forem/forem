function initializeCommentDropdown() {
  setTimeout(function () {
    var allDropdowns = document.getElementsByClassName('dropbtn');
    for (i = 0; i < allDropdowns.length; i++) {
      allDropdowns[i].onclick = dropdownFunction
    }
  }, 100);

  function dropdownFunction(e) {
    var button = e.target.parentElement;
    var currentElement = button.parentElement.getElementsByClassName('dropdown-content')[0];
    if (currentElement.classList.contains('showing')) {
      currentElement.classList.remove('showing');
      removeClickListener();
    } else {
      removeAllShowing();
      currentElement.classList.add('showing');
      document.addEventListener('click', outsideClickListener);
    }
  }

  function outsideClickListener(event) {
    if (shouldCloseDropdown(event)) {
      removeAllShowing()
      removeClickListener();
    }
  }

  function shouldCloseDropdown(event) {
    return !(event.target.matches('.dropdown-icon') ||
      event.target.matches('.dropbtn') ||
      event.target.parentElement.classList.contains("dropdown-link-row"))
  }

  function removeClickListener() {
    document.removeEventListener('click', outsideClickListener);
  }

  function removeAllShowing() {
    var allDropdowns = document.getElementsByClassName('showing');
    for (var i = 0; i < allDropdowns.length; i += 1) {
      allDropdowns[i].classList.remove('showing');
    }
  }
}
