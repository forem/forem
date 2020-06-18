import { h } from 'preact';
import { render } from '@testing-library/preact';
import { ReadingList } from '../readingList';

describe('<ReadingList />', () => {
  it('renders all the elements', () => {
    const { getByPlaceholderText, getByText } = render(<ReadingList availableTags={['discuss']} />);

    getByPlaceholderText('search your list');
    getByText('#discuss');
    getByText('View Archive');
    getByText('Your Archive List is Lonely');
    getByText('Reading List (empty)');
  });
});
