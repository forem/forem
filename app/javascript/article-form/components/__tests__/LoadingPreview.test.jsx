import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { LoadingPreview } from '..';

describe('<LoadingPreview />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<LoadingPreview />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByTitle } = render(<LoadingPreview />);

    expect(queryByTitle('Loading preview...')).toBeDefined();
  });

  it('should render with cover image', () => {
    const { queryByTitle } = render(<LoadingPreview version="cover" />);

    expect(queryByTitle('Loading preview...')).toBeDefined();
  });
});
