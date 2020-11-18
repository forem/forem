import { h } from 'preact';
import { Search } from '../Search';
import { instantClickRender } from '@utilities/preact/render';
import 'focus-visible';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('header-search');

  instantClickRender(<Search />, root);
});
