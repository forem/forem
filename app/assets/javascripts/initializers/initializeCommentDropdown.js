// eslint-disable-next-line no-unused-vars
function initializeCommentDropdown() {
  const announcer = document.getElementById('article-copy-link-announcer');

  function isIOSDevice() {
    return (
      navigator.userAgent.match(/iPhone/i) ||
      navigator.userAgent.match('CriOS') ||
      navigator.userAgent.match(/iPad/i) ||
      navigator.userAgent === 'DEV-Native-ios'
    );
  }

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

  function iOSCopyText() {
    const input = document.getElementById('article-copy-link-input');
    input.setSelectionRange(0, input.value.length);
    document.execCommand('copy');
    showAnnouncer();
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
    if (isIOSDevice) {
      const clipboardCopyElement = document.getElementsByTagName(
        'clipboard-copy',
      )[0];
      clipboardCopyElement.removeEventListener('click', iOSCopyText);
    } else {
      document.removeEventListener('clipboard-copy', showAnnouncer);
    }
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
    var dropdownContent = button.parentElement.getElementsByClassName(
      'dropdown-content',
    )[0];
    if (dropdownContent.classList.contains('showing')) {
      dropdownContent.classList.remove('showing');
      removeClickListener();
      removeCopyListener();
      hideAnnouncer();
    } else {
      removeAllShowing();
      dropdownContent.classList.add('showing');
      if (isIOSDevice) {
        const clipboardCopyElement = document.getElementsByTagName(
          'clipboard-copy',
        )[0];

        document.addEventListener('click', outsideClickListener);
        clipboardCopyElement.addEventListener('click', iOSCopyText);
      } else {
        document.addEventListener('click', outsideClickListener);
        document.addEventListener('clipboard-copy', showAnnouncer);
      }
    }
  }

  function addDropdownListener(dropdown) {
    dropdown.addEventListener('click', dropdownFunction);
  }

  setTimeout(function addListeners() {
    getAllByClassName('dropbtn').forEach(addDropdownListener);
  }, 100);
}
