/* global Runtime */

function initializeCommentDropdown() {
  const announcer = document.getElementById('article-copy-link-announcer');

  function removeClass(className) {
    return (element) => element.classList.remove(className);
  }

  function getAllByClassName(className) {
    return Array.from(document.getElementsByClassName(className));
  }

  function showAnnouncer() {
    const { activeElement } = document;
    const input =
      activeElement.localName === 'clipboard-copy'
        ? activeElement.querySelector('input')
        : document.getElementById('article-copy-link-input');
    input.focus();
    input.setSelectionRange(0, input.value.length);
    announcer.hidden = false;
  }

  function hideAnnouncer() {
    if (announcer) {
      announcer.hidden = true;
    }
  }

  function copyText() {
    const inputValue = document.getElementById('article-copy-link-input').value;
    Runtime.copyToClipboard(inputValue).then(() => {
      showAnnouncer();
    });
  }

  function shouldCloseDropdown(event) {
    return !(
      event.target.matches('.dropdown-icon') ||
      event.target.matches('.dropbtn') ||
      event.target.matches('clipboard-copy') ||
      document.getElementById('article-copy-icon').contains(event.target) ||
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
    const clipboardCopyElement = document.getElementsByTagName(
      'clipboard-copy',
    )[0];
    if (clipboardCopyElement) {
      clipboardCopyElement.removeEventListener('click', copyText);
    }
  }

  function removeAllShowing() {
    getAllByClassName('crayons-dropdown').forEach(removeClass('block'));
  }

  function outsideClickListener(event) {
    if (shouldCloseDropdown(event)) {
      removeAllShowing();
      hideAnnouncer();
      removeClickListener();
    }
  }

  function dropdownFunction(e) {
    const button = e.currentTarget;
    const dropdownContent = button.parentElement.getElementsByClassName(
      'crayons-dropdown',
    )[0];

    if (!dropdownContent) {
      return;
    }

    // Android native apps have enhanced sharing capabilities for Articles
    const articleShowMoreClicked = button.id === 'article-show-more-button';
    if (articleShowMoreClicked && Runtime.isNativeAndroid('shareText')) {
      AndroidBridge.shareText(location.href);
      return;
    }

    finalizeAbuseReportLink(
      dropdownContent.querySelector('.report-abuse-link-wrapper'),
    );

    if (dropdownContent.classList.contains('block')) {
      dropdownContent.classList.remove('block');
      removeClickListener();
      removeCopyListener();
      hideAnnouncer();
    } else {
      removeAllShowing();
      dropdownContent.classList.add('block');
      const clipboardCopyElement = document.getElementsByTagName(
        'clipboard-copy',
      )[0];

      document.addEventListener('click', outsideClickListener);
      if (clipboardCopyElement) {
        clipboardCopyElement.addEventListener('click', copyText);
      }
    }
  }

  function finalizeAbuseReportLink(reportAbuseLink) {
    // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
    if (!reportAbuseLink) {
      return;
    }

    reportAbuseLink.innerHTML = `<a href="${reportAbuseLink.dataset.path}" class="crayons-link crayons-link--block">Report Abuse</a>`;
  }

  function addDropdownListener(dropdown) {
    dropdown.addEventListener('click', dropdownFunction);
  }

  setTimeout(function addListeners() {
    getAllByClassName('dropbtn').forEach(addDropdownListener);
  }, 100);
}
