import { h } from 'preact';
import ListingForm from '../listings/listingForm';
import { render } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('listingform-data');
  if (root) {
    const {
      listing,
      organizations,
      categoriesForSelect,
      categoriesForDetails,
    } = root.dataset;
    render(
      <ListingForm
        organizations={organizations}
        listing={listing}
        categoriesForSelect={categoriesForSelect}
        categoriesForDetails={categoriesForDetails}
      />,
      root,
    );
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
