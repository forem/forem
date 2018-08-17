import { h, render } from 'preact';
import { Search } from '../src/views/Search';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('nav-search-form-root');

  render(<Search />, root, root.firstElementChild);
});
