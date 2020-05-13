import { h } from 'preact';
import render from 'preact-render-to-json';
import { Close } from '../Close';

describe('<Close />', () => {
  it('renders properly', () => {
    const tree = render(<Close />);
    expect(tree).toMatchSnapshot();
  });
});
