import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ItemListLoadMoreButton } from '../ItemListLoadMoreButton';

describe('<ItemListLoadMoreButton />', () => {
  it('should have no a11y violations when the load more button is not shown', async () => {
    const { container } = render(<ItemListLoadMoreButton show={false} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when the load more button is shown', async () => {
    const { container } = render(<ItemListLoadMoreButton show={true} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders nothing when not required', () => {
    const { queryByText } = render(<ItemListLoadMoreButton show={false} />);
    expect(queryByText(/load more/i)).toBeNull();
  });

  it('renders a button when required', () => {
    const { queryByText } = render(<ItemListLoadMoreButton show={true} />);

    expect(queryByText(/load more/i)).toBeDefined();
  });
});
