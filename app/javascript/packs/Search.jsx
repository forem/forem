import { h, render } from 'preact';
import { Search } from '../src/components/Search';
import 'focus-visible'

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('top-bar--search');

  render(<Search />, root, root.firstElementChild);
});
