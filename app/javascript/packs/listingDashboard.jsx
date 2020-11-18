import { h } from 'preact';
import { ListingDashboard } from '../listings/listingDashboard';
import { instantClickRender } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('listings-dashboard');
  if (root) {
    instantClickRender(<ListingDashboard />, root);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
