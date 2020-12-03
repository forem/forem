import { h, render } from 'preact';
import 'focus-visible';
import { SearchFormSync } from '../Search/SearchFormSync';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('header-search');

  render(<SearchFormSync />, root);
});
