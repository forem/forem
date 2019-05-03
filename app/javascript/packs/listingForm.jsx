import { h, render } from 'preact';
import ListingForm from '../listings/listingForm';

const root = document.getElementById('listingform-data');
const { listing, organizations, categoriesForSelect, categoriesForDetails } = root.dataset;

render(
  <ListingForm
    organizations={organizations}
    listing={listing}
    categoriesForSelect={categoriesForSelect}
    categoriesForDetails={categoriesForDetails}
  />,
  root,
);
