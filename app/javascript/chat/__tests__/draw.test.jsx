import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import Draw from '../draw';

describe('<Draw />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<Draw />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText } = render(<Draw />);

    expect(queryByText('Connect Draw')).toBeDefined();
    expect(queryByText('Clear')).toBeDefined();
    expect(queryByText('Send')).toBeDefined();
  });
});
