import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ItemListItemArchiveButton } from '../ItemListItemArchiveButton';

describe('<ItemListItemArchiveButton />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ItemListItemArchiveButton text="archive" />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders the Archive button', () => {
    const { getByText } = render(<ItemListItemArchiveButton text="archive" />);
    getByText(/archive/i);
  });

  it('triggers the onClick if the Enter key is pressed', () => {
    const onClick = jest.fn();
    const { getByRole } = render(
      <ItemListItemArchiveButton text="archive" onClick={onClick} />,
    );

    fireEvent.keyUp(getByRole('button'), { key: 'Enter', code: 'Enter' });
    expect(onClick).toHaveBeenCalledTimes(1);

    fireEvent.keyUp(getByRole('button'), { key: 'Space', code: 'Space' });
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
