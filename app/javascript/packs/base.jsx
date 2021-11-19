/* global Runtime */
import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  initializeMemberMenu,
} from '../topNavigation/utilities';
import { waitOnBaseData } from '../utilities/waitOnBaseData';

// Unique ID applied to modals created using window.Forem.showModal
const WINDOW_MODAL_ID = 'window-modal';

// Namespace for functions which need to be accessed in plain JS initializers
window.Forem = {
  preactImport: undefined,
  getPreactImport() {
    if (!this.preactImport) {
      this.preactImport = import('preact');
    }
    return this.preactImport;
  },
  mentionAutoCompleteImports: undefined,
  getMentionAutoCompleteImports() {
    if (!this.mentionAutoCompleteImports) {
      this.mentionAutoCompleteImports = [
        import('@crayons/MentionAutocompleteTextArea'),
        import('@utilities/search'),
        this.getPreactImport(),
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

    const [{ MentionAutocompleteTextArea }, { fetchSearch }, { render, h }] =
      await window.Forem.getMentionAutoCompleteImports();

    render(
      <MentionAutocompleteTextArea
        replaceElement={originalTextArea}
        fetchSuggestions={(username) => fetchSearch('usernames', { username })}
      />,
      parentContainer,
      originalTextArea,
    );
  },
  modalImports: undefined,
  getModalImports() {
    if (!this.modalImports) {
      this.modalImports = [import('@crayons/Modal'), this.getPreactImport()];
    }
    return Promise.all(this.modalImports);
  },
  showModal: async ({
    title,
    contentSelector,
    overlay = false,
    size = 's',
    onOpen,
  }) => {
    const [{ Modal }, { render, h }] = await window.Forem.getModalImports();

    // Guard against two modals being opened at once
    let currentModalContainer = document.getElementById(WINDOW_MODAL_ID);
    if (currentModalContainer) {
      render(null, currentModalContainer);
    } else {
      currentModalContainer = document.createElement('div');
      currentModalContainer.setAttribute('id', WINDOW_MODAL_ID);
      document.body.appendChild(currentModalContainer);
    }

    render(
      <Modal
        overlay={overlay}
        title={title}
        onClose={() => {
          render(null, currentModalContainer);
        }}
        size={size}
        focusTrapSelector={`#${WINDOW_MODAL_ID}`}
      >
        <div
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: document.querySelector(contentSelector).innerHTML,
          }}
        />
      </Modal>,
      currentModalContainer,
    );

    onOpen?.();
  },
  closeModal: async () => {
    const currentModalContainer = document.getElementById(WINDOW_MODAL_ID);
    if (currentModalContainer) {
      const { render } = await window.Forem.getPreactImport();
      render(null, currentModalContainer);
    }
  },
};

function getPageEntries() {
  return Object.entries({
    'notifications-index': document.getElementById('notifications-link'),
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
  const moreMenus = [...document.getElementsByClassName('js-nav-more-trigger')];

  setCurrentPageIconLink(currentPage, getPageEntries());
  initializeMobileMenu(menuTriggers, moreMenus);
}

const memberMenu = document.getElementById('crayons-header__menu');
const menuNavButton = document.getElementById('member-menu-button');

if (memberMenu) {
  initializeMemberMenu(memberMenu, menuNavButton);
}

// Initialize when asset pipeline (sprockets) initializers have executed
waitOnBaseData()
  .then(() => {
    InstantClick.on('change', () => {
      initializeNav();
    });

    if (Runtime.currentMedium() === 'ForemWebView') {
      // Dynamic import of the namespace
      import('../mobile/foremMobile.js').then((module) => {
        // Load the namespace
        window.ForemMobile = module.foremMobileNamespace();
        // Run the first session
        window.ForemMobile.userSessionBroadcast();
      });
    }
  })
  .catch((error) => {
    Honeybadger.notify(error);
  });

initializeNav();

async function loadCreatorSettings() {
  try {
    const [{ CreatorSettingsController }, { Application }] = await Promise.all([
      import('@admin-controllers/creator_settings_controller'),
      import('@hotwired/stimulus'),
    ]);

    const application = Application.start();
    application.register('creator-settings', CreatorSettingsController);
  } catch (error) {
    Honeybadger.notify(
      `Error loading the creator settings controller: ${error.message}`,
    );
  }
}

if (document.location.pathname === '/admin/creator_settings/new') {
  loadCreatorSettings();
}
