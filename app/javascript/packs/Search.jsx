import { h, render } from 'preact';
import { Search } from '../src/components/Search';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('nav-search-form-root');

  render(<Search />, root, root.firstElementChild);
});
