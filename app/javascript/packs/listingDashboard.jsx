import { h, render } from 'preact';
import { ListingDashboard } from '../listings/listingDashboard';

function loadElement() {
  const root = document.getElementById('classifieds-listings-dashboard');
  if (root) {
    render(<ListingDashboard />, root, root.firstElementChild);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
