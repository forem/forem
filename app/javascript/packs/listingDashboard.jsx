import { h } from 'preact';
import { ListingDashboard } from '../listings/listingDashboard';
import { render } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('listings-dashboard');
  if (root) {
    render(<ListingDashboard />, root);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
