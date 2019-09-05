import { h } from 'preact';
import { deep, shallow } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import ListingForm from '../listingForm';

const organizations = '{}';
const listing = '{}';
const categoriesForSelect = '[]';
const categoriesForDetails = '[]';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.document.body.innerHTML = ``;
global.window = doc.defaultView;

describe('<ListingForm />', () => {
  it('should load listingForm', () => {
    const tree = deep(
      <ListingForm
        organizations={organizations}
        listing={listing}
        categoriesForSelect={categoriesForSelect}
        categoriesForDetails={categoriesForDetails}
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
