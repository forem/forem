import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { CogIcon } from '../CogIcon';

describe('<CommentSubscription />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<CogIcon />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
  it('should render', () => {
    const { container } = render(<CogIcon />);

    expect(container.innerHTML).toMatchSnapshot();
  });
});
