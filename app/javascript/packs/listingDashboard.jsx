import { h, render } from 'preact';
import { ListingDashboard } from '../listings/listingDashboard';

function loadElement() {
  const root = document.getElementById('listings-dashboard');
  if (root) {
    render(<ListingDashboard />, root, root.firstElementChild);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
