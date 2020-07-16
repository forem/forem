import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import Tags from '../tags';

describe('<Tags />', () => {
  beforeAll(() => {
    const environment = document.createElement('meta');
    environment.setAttribute('name', 'environment');
    document.body.appendChild(environment);
  });

  it('should have no a11y violations', async () => {
    const { container } = render(<Tags defaultValue="defaultValue" listing />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
