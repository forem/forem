import { h, render } from 'preact';
import { Search } from '../Search';
import 'focus-visible';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('header-search');

  render(<Search />, root);
});
