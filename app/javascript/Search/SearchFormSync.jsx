import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { createPortal, Fragment, unmountComponentAtNode } from 'preact/compat';
import { Search } from './Search';
import { getSearchTermFromUrl } from '@utilities/search';

/**
 * Manages the synchronization of search state between the top search bar (desktop) and
 * mobile (in search results page).
 */
export function SearchFormSync() {
  const [searchTerm, setSearchTerm] = useState(() => {
    return getSearchTermFromUrl(location.search);
  });
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
    const mscElement = document.getElementById('mobile-search-container');

    // The DOM element has changed because server-sde rendering returns new
    // search results which destroys the existing search form in mobile view.
    // Because of this we need to unmount the component at the old element reference
    // i.e. the container for the createPortal call in the render.
    // If we do not unmount, it will result in an unmounting error that will throw as the
    // container element (search form that was wiped out because of the new search results) no longer exists.
    if (mobileSearchContainer && mscElement !== mobileSearchContainer) {
      unmountComponentAtNode(mobileSearchContainer);
    }

    // We need to delete the existing server-side rendered form because createPortal only appends to it's container.
    if (mscElement) {
      const form = mscElement.querySelector('form');
      // We remove the child form expecting that createPortal adds the new form on each re-render
      form && mscElement.removeChild(form);
    }

    // Since, passing the reference to same element will not cause the component to re-render
    // we CLONE & REPLACE the element with the clone & pass the clone's reference, so that useState
    // will re-render the component.
    const mscElementClone = mscElement ? mscElement.cloneNode(true) : null;

    if (mscElementClone) {
      const mscElementParent = mscElement.parentElement;
      unmountComponentAtNode(mscElement);
      mscElementParent.prepend(mscElementClone);
    }

    setMobileSearchContainer(mscElementClone);
    setSearchTerm(updatedSearchTerm);
  }

  useEffect(() => {
    window.addEventListener('syncSearchForms', syncSearchFormsListener);

    return () => {
      window.removeEventListener('syncSearchForms', syncSearchFormsListener);
    };
  });

  const branding = document.body.dataset.algoliaDisplay === 'true' ? 'algolia' : 'default';

  return (
    <Fragment>
      <Search searchTerm={searchTerm} setSearchTerm={setSearchTerm} branding={branding} />
      {mobileSearchContainer &&
        createPortal(
          <Search searchTerm={searchTerm} setSearchTerm={setSearchTerm} />,
          mobileSearchContainer,
        )}
    </Fragment>
  );
}
