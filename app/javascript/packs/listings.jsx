import { h, render } from 'preact';
import { Listings } from '../listings/listings';

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
