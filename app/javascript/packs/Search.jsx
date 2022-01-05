import { h, render } from 'preact';
import { SearchFormSync } from '../Search/SearchFormSync';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('header-search');

  render(<SearchFormSync />, root);
});
