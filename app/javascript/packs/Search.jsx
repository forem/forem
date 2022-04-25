import { h, render } from 'preact';
import { SearchFormSync } from '../Search/SearchFormSync';

document.addEventListener('DOMContentLoaded', () => {
  const headerSearch = document.getElementById('header-search');
  const mobileSearchContainer = document.getElementById(
    'mobile-search-container',
  );

  render(<SearchFormSync />, headerSearch);
  render(<SearchFormSync />, mobileSearchContainer);
});
