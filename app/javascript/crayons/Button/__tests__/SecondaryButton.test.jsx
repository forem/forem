import { h } from 'preact';
import render from 'preact-render-to-json';
import { SecondaryButton } from '@crayons';

describe('<SecondaryButton /> component', () => {
  it('should render', () => {
    const tree = render(<SecondaryButton>Hello world!</SecondaryButton>);
    expect(tree).toMatchSnapshot();
  });
});
