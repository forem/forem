import { h } from 'preact';
import { Listings } from '../listings/listings';
import { render } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('listings-index-container');
  if (root) {
    render(<Listings />, root);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
