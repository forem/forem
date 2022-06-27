import 'focus-visible';
import {
  initializeMobileMenu,
  setCurrentPageIconLink,
  initializeMemberMenu,
} from '../topNavigation/utilities';
import { waitOnBaseData } from '../utilities/waitOnBaseData';
import { showWindowModal, closeWindowModal } from '@utilities/showModal';
import * as Runtime from '@utilities/runtime';

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
  showModal: showWindowModal,
  closeModal: () => closeWindowModal(),
  Runtime,
};

function getPageEntries() {
  return Object.entries({
    'notifications-index': document.getElementById('notifications-link'),
    'moderations-index': document.getElementById('moderation-link'),
    'articles_search-index': document.getElementById('search-link'),
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
    const [{ LogoUploadController }, { Application }] = await Promise.all([
      import('@admin/controllers/logo_upload_controller'),
      import('@hotwired/stimulus'),
    ]);

    const application = Application.start();
    application.register('logo-upload', LogoUploadController);
  } catch (error) {
    Honeybadger.notify(
      `Error loading the creator settings controller: ${error.message}`,
    );
  }
}

if (document.location.pathname === '/admin/creator_settings/new') {
  loadCreatorSettings();
}
