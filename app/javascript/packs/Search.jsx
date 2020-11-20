import { Fragment, h, render } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { createPortal, unmountComponentAtNode } from 'preact/compat';
import 'focus-visible';
import { Search } from '../Search';
import {
  displaySearchResults,
  getInitialSearchTerm,
  preloadSearchResults,
} from '@utilities/search';

// TODO: Pull this out of the pack file.
function SearchFormSync() {
  const [searchTerm, setSearchTerm] = useState(
    getInitialSearchTerm(location.search),
  );
  const [mobileSearchContainer, setMobileSearchContainer] = useState(null);

  function syncSearchFormsListener() {
    const updatedSearchTerm = getInitialSearchTerm(location.search);

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

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('header-search');

  render(<SearchFormSync />, root);
});
