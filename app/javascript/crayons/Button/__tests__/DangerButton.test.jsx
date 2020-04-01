import { h } from 'preact';
import render from 'preact-render-to-json';
import { DangerButton } from '@crayons';

describe('<DangerButton /> component', () => {
  it('should render', () => {
    const tree = render(<DangerButton>Hello world!</DangerButton>);
    expect(tree).toMatchSnapshot();
  });
});
