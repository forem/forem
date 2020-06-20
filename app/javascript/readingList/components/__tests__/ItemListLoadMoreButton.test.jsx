import { h } from 'preact';
import { render } from '@testing-library/preact';
import { ItemListLoadMoreButton } from '../ItemListLoadMoreButton';

describe('<ItemListLoadMoreButton />', () => {
  it('renders nothing when not required', () => {
    const { queryByText } = render(<ItemListLoadMoreButton show={false}  />);
    expect(queryByText(/load more/i)).toBeNull();
  });

  it('renders a button when required', () => {
    const { getByText } = render(<ItemListLoadMoreButton show={true} />);
    getByText(/load more/i);
  });
});
