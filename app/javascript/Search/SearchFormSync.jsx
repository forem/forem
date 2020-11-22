import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { createPortal, Fragment, unmountComponentAtNode } from 'preact/compat';
import { Search } from './Search';
import {
  displaySearchResults,
  getSearchTermFromUrl,
  preloadSearchResults,
} from '@utilities/search';

/**
 * Manages the synchronization of search state between the top search bar (desktop) and
 * mobile (in search results page).
 */
export function SearchFormSync() {
  const [searchTerm, setSearchTerm] = useState(
    getSearchTermFromUrl(location.search),
  );
  const [mobileSearchContainer, setMobileSearchContainer] = useState(null);

  /**
   * A listener for handling the synchronization of search forms.
   *
   * @param {CustomEvent<{ querystring: string }>} event A custom event for synching search forms.
   */
  function syncSearchFormsListener(event) {
    const { querystring } = event.detail;
    const updatedSearchTerm = getSearchTermFromUrl(querystring);

    // Server-side rendering of search results means the DOM node is destroyed everytime a search is performed,
    // So we need to get the reference every time and use that for the parent in the portal.
    const element = document.getElementById('mobile-search-container');

    // The DOM element has changed because server-sde rendering returns new
    // search results which destroys the existing search form in mobile view.
    // Because of this we need to unmount the component at the old element reference
    // i.e. the container for the createPortal call in the render.
    // If we do not unmount, it will result in an unmounting error that will throw as the
    // container element (search form that was wiped out because of the new search results) no longer exists.
    if (mobileSearchContainer && element !== mobileSearchContainer) {
      unmountComponentAtNode(mobileSearchContainer);
    }

    setMobileSearchContainer(element);

    // We need to delete the existing server side rendered form because createPortal only appends to it's parent.
    if (element) {
      const form = element.querySelector('form');
      form && element.removeChild(form);
    }

    setSearchTerm(updatedSearchTerm);
  }

  useEffect(() => {
    window.addEventListener('syncSearchForms', syncSearchFormsListener);

    return () => {
      window.removeEventListener('syncSearchForms', syncSearchFormsListener);
    };
  });

  useEffect(() => {
    preloadSearchResults({ searchTerm });
    displaySearchResults({ searchTerm });
  }, [searchTerm]);

  return (
    <Fragment>
      <Search searchTerm={searchTerm} setSearchTerm={setSearchTerm} />
      {mobileSearchContainer &&
        createPortal(
          <Search searchTerm={searchTerm} setSearchTerm={setSearchTerm} />,
          mobileSearchContainer,
        )}
    </Fragment>
  );
}
