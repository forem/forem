import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { Close } from '../Close';

describe('<Close />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<Close />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders the close button', () => {
    const { getByRole } = render(<Close />);
    const icon = getByRole('button', { name: /Close the editor/i });
    expect(icon).toBeInTheDocument();
  });
});
