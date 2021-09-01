import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ItemListItemArchiveButton } from '../ItemListItemArchiveButton';

describe('<ItemListItemArchiveButton />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ItemListItemArchiveButton text="archive" />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders the Archive button', () => {
    const { queryByText } = render(
      <ItemListItemArchiveButton text="archive" />,
    );

    expect(queryByText(/archive/i)).toBeDefined();
  });
});
