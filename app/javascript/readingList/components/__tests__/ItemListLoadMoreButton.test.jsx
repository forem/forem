import { h } from 'preact';
import { render } from '@testing-library/preact';
import { ItemListLoadMoreButton } from '../ItemListLoadMoreButton';

describe('<ItemListLoadMoreButton />', () => {
  it('renders nothing when not required', () => {
    const { queryByTestId } = render(<ItemListLoadMoreButton show={false}  />);
    expect(queryByTestId('load-more-button')).toBeNull();
  });

  it('renders a button when required', () => {
    const { getByTestId } = render(<ItemListLoadMoreButton show={true} />);
    expect(getByTestId('load-more-button')).toBeTruthy();
  });
});
