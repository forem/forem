import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  getInstantClick,
  initializeTouchDevice,
} from '../topNavigation/utilities';
import { fetchSearch } from '@utilities/search';

// Namespace for functions which need to be accessed in plain JS initializers
window.Forem = {};

window.Forem.initializeMentionAutocomplete = async (element) => {
  const [
    { MentionAutocomplete },
    { render, h, createRef },
  ] = await Promise.all([
    import('@crayons/MentionAutocomplete'),
    import('preact'),
  ]);

  let autocompleteContainer = document.getElementById('autocomplete-container');
  if (!autocompleteContainer) {
    autocompleteContainer = document.createElement('span');
    autocompleteContainer.id = 'autocomplete-container';
    document.body.appendChild(autocompleteContainer);
  }

  const elementRef = createRef();
  elementRef.current = element;

  render(
    <MentionAutocomplete
      textAreaRef={elementRef}
      fetchSuggestions={(username) => {
        return fetchSearch('usernames', {
          username,
        });
      }}
    />,
    autocompleteContainer,
    autocompleteContainer.lastChild,
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
