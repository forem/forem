import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  getInstantClick,
  initializeTouchDevice,
} from '../topNavigation/utilities';

// Namespace for functions which need to be accessed in plain JS initializers
window.Forem = {
  mentionAutoCompleteImports: undefined,
  getMentionAutoCompleteImports() {
    if (!this.mentionAutoCompleteImports) {
      this.mentionAutoCompleteImports = [
        import('@crayons/MentionAutocompleteTextArea'),
        import('@utilities/search'),
        import('preact'),
      ];
    }

    // We're still returning Promises, but if the they have already been imported
    // they will now be fulfilled instead of pending, i.e. a network request is no longer made.
    return Promise.all(this.mentionAutoCompleteImports);
  },
  initializeMentionAutocompleteTextArea: async (originalTextArea) => {
    const parentContainer = originalTextArea.parentElement;

    const alreadyInitialized = parentContainer.id === 'combobox-container';
    if (alreadyInitialized) {
      return;
    }

    const [
      { MentionAutocompleteTextArea },
      { fetchSearch },
      { render, h },
    ] = await window.Forem.getMentionAutoCompleteImports();

    render(
      <MentionAutocompleteTextArea
        replaceElement={originalTextArea}
        fetchSuggestions={(username) => fetchSearch('usernames', { username })}
      />,
      parentContainer,
      originalTextArea,
    );
  },
};

window.showModal = async ({
  title,
  contentSelector,
  overlay = false,
  size = 's',
}) => {
  const [{ Modal }, { render, h }] = await Promise.all([
    import('@crayons/Modal'),
    import('preact'),
  ]);

  const modalRoot = document.createElement('div');
  document.body.appendChild(modalRoot);

  render(
    <Modal
      overlay={overlay}
      title={title}
      onClose={() => {
        render(null, modalRoot);
      }}
      size={size}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: document.querySelector(contentSelector).innerHTML,
        }}
      />
    </Modal>,
    modalRoot,
  );
};

function getPageEntries() {
  return Object.entries({
    'notifications-index': document.getElementById('notifications-link'),
    'chat_channels-index': document.getElementById('connect-link'),
    'moderations-index': document.getElementById('moderation-link'),
    'stories-search': document.getElementById('search-link'),
  });
}

function initializeNav() {
  const { currentPage } = document.getElementById('page-content').dataset;
  const menuTriggers = [
    ...document.querySelectorAll(
      '.js-hamburger-trigger, .hamburger a:not(.js-nav-more-trigger)',
    ),
  ];
  const memberMenu = document.getElementById('crayons-header__menu');
  const menuNavButton = document.getElementById('member-menu-button');
  const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

  setCurrentPageIconLink(currentPage, getPageEntries());
  initializeMobileMenu(menuTriggers, moreMenus);
  initializeTouchDevice(memberMenu, menuNavButton);
}

getInstantClick().then((spa) => {
  spa.on('change', initializeNav);
});

initializeNav();
