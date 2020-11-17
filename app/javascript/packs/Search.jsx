import { h } from 'preact';
import { Search } from '../Search';
import { render } from '@utilities/preact';
import 'focus-visible';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('header-search');

  render(<Search />, root);
});
