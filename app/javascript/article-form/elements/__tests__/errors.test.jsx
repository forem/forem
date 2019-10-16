import { h } from 'preact';
import render from 'preact-render-to-json';
import Errors from '../errors';

const errorsList = [
  'Error 1',
  'Error 2'
];

describe('<Errors />', () => {
  it('renders properly', () => {
    const tree = render(<Errors errorsList={errorsList} />);
    expect(tree).toMatchSnapshot();
  });
});
