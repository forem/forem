import { h } from 'preact';
import { render } from '@testing-library/preact';
import { ReadingList } from '../readingList';

describe('<ReadingList />', () => {
  it('renders all the elements', () => {
    const { getByPlaceholderText, getByText } = render(<ReadingList availableTags={['discuss']} />);

    expect(getByPlaceholderText('search your list')).toBeTruthy();
    expect(getByText('#discuss')).toBeTruthy();
    expect(getByText('View Archive')).toBeTruthy();
    expect(getByText('Your Archive List is Lonely')).toBeTruthy();
    expect(getByText('Reading List (empty)')).toBeTruthy();
  });
});
