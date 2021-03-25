import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  getInstantClick,
  initializeTouchDevice,
} from '../topNavigation/utilities';

// Namespace for functions which need to be accessed in plain JS initializers
window.Forem = {};

window.Forem.initializeMentionAutocompleteTextArea = async (
  originalTextArea,
) => {
  const parentContainer = originalTextArea.parentElement;

  const alreadyInitialized = parentContainer.id === 'combobox-container';
  if (alreadyInitialized) {
    return;
  }

  const [
    { MentionAutocompleteTextArea },
    { fetchSearch },
    { render, h },
  ] = await Promise.all([
    import('@crayons/MentionAutocompleteTextArea'),
    import('@utilities/search'),
    import('preact'),
  ]);

  render(
    <MentionAutocompleteTextArea
      replaceElement={originalTextArea}
      fetchSuggestions={(username) => fetchSearch('usernames', { username })}
    />,
    parentContainer,
    originalTextArea,
  );
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

const menuTriggers = [
  ...document.querySelectorAll(
    '.js-hamburger-trigger, .hamburger a:not(.js-nav-more-trigger)',
  ),
];
const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

getInstantClick().then((spa) => {
  spa.on('change', () => {
    const { currentPage } = document.getElementById('page-content').dataset;

    setCurrentPageIconLink(currentPage, getPageEntries());
  });
});

const { currentPage } = document.getElementById('page-content').dataset;
const memberMenu = document.getElementById('crayons-header__menu');
const menuNavButton = document.getElementById('member-menu-button');

setCurrentPageIconLink(currentPage, getPageEntries());
initializeMobileMenu(menuTriggers, moreMenus);
initializeTouchDevice(memberMenu, menuNavButton);
