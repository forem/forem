// eslint-disable-next-line no-unused-vars
function initializeCommentDropdown() {
  const announcer = document.getElementById('article-copy-link-announcer');

  function removeClass(className) {
    return element => element.classList.remove(className);
  }

  function getAllByClassName(className) {
    return Array.from(document.getElementsByClassName(className));
  }

  function showAnnouncer() {
    const { activeElement } = document;
    const input =
      activeElement.localName === 'clipboard-copy'
        ? activeElement.querySelector('input')
        : activeElement;
    input.focus();
    input.setSelectionRange(0, input.value.length);
    announcer.hidden = false;
  }

  function hideAnnouncer() {
    announcer.hidden = true;
  }

  function shouldCloseDropdown(event) {
    return !(
      event.target.matches('.dropdown-icon') ||
      event.target.matches('.dropbtn') ||
      event.target.matches('clipboard-copy') ||
      event.target.matches('clipboard-copy input') ||
      event.target.matches('clipboard-copy img') ||
      event.target.parentElement.classList.contains('dropdown-link-row')
    );
  }

  function removeClickListener() {
    // disabling this rule because `removeEventListener` needs
    // a reference to the specific handler. The function is hoisted.
    // eslint-disable-next-line no-use-before-define
    document.removeEventListener('click', outsideClickListener);
  }

  function removeCopyListener() {
    document.removeEventListener('clipboard-copy', showAnnouncer);
  }

  function removeAllShowing() {
    getAllByClassName('showing').forEach(removeClass('showing'));
  }

  function outsideClickListener(event) {
    if (shouldCloseDropdown(event)) {
      removeAllShowing();
      hideAnnouncer();
      removeClickListener();
    }
  }

  function dropdownFunction(e) {
    var button = e.target.parentElement;
    var { parentElement: parent } = button;
    var [dropdownContent] = parent.getElementsByClassName('dropdown-content');
    if (dropdownContent.classList.contains('showing')) {
      dropdownContent.classList.remove('showing');
      removeClickListener();
      removeCopyListener();
      hideAnnouncer();
    } else {
      removeAllShowing();
      dropdownContent.classList.add('showing');
      document.addEventListener('click', outsideClickListener);
      document.addEventListener('clipboard-copy', showAnnouncer);
    }
  }

  function addDropdownListener(dropdown) {
    dropdown.addEventListener('click', dropdownFunction);
  }

  setTimeout(function addListeners() {
    getAllByClassName('dropbtn').forEach(addDropdownListener);
  }, 100);
}
