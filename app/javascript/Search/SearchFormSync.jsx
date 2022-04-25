import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
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

  /**
   * A listener for handling the synchronization of search forms.
   *
   * @param {CustomEvent<{ querystring: string }>} event A custom event for synching search forms.
   */
  function syncSearchFormsListener(event) {
    const { querystring } = event.detail;
    const updatedSearchTerm = getSearchTermFromUrl(querystring);
    setSearchTerm(updatedSearchTerm);
  }

  useEffect(() => {
    window.addEventListener('syncSearchForms', syncSearchFormsListener);

    return () => {
      window.removeEventListener('syncSearchForms', syncSearchFormsListener);
    };
  });

  return <Search searchTerm={searchTerm} setSearchTerm={setSearchTerm} />;
}
