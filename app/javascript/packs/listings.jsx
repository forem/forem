import { h } from 'preact';
import { Listings } from '../listings/listings';
import { instantClickRender } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('listings-index-container');
  if (root) {
    instantClickRender(<Listings />, root);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
