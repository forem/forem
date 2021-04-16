import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Alert } from '../alert';

describe('<Alert />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<Alert showAlert />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render an alert', () => {
    const { queryByRole } = render(<Alert showAlert />);

    expect(queryByRole('alert')).toBeDefined();
  });

  it('should not render an alert', () => {
    const { queryByRole } = render(<Alert />);

    const alert = queryByRole('alert');

    expect(alert).toBeNull();
  });
});
