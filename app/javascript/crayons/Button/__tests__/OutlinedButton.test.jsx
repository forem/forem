import { h } from 'preact';
import render from 'preact-render-to-json';
import { OutlinedButton } from '@crayons';

describe('<OutlinedButton /> component', () => {
  it('should render', () => {
    const tree = render(<OutlinedButton>Hello world!</OutlinedButton>);
    expect(tree).toMatchSnapshot();
  });
});
