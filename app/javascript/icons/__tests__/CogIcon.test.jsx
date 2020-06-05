import { h } from 'preact';
import { render } from '@testing-library/preact';
import { CogIcon } from '../CogIcon';

describe('<CommentSubscription />', () => {
  it('should render', () => {
    const { container } = render(<CogIcon />);

    expect(container.innerHTML).toMatchSnapshot();
  });
});
