import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Spinner } from '../Spinner';

describe('<Spinner />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<Spinner />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
