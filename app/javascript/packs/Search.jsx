import { h, render } from 'preact';
import { Search } from '../Search';
import 'focus-visible';

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.js-search-form').forEach(function (search) {
    render(<Search />, search);
  });
});
