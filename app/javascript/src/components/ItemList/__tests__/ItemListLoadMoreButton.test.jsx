import { h } from 'preact';
import render from 'preact-render-to-json';
import { ItemListLoadMoreButton } from '../ItemListLoadMoreButton';

describe('<ItemListLoadMoreButton />', () => {
  it('renders properly', () => {
    const tree = render(<ItemListLoadMoreButton show />);
    expect(tree).toMatchSnapshot();
  });

  it('renders nothing if not required', () => {
    const tree = render(<ItemListLoadMoreButton show={false} />);
    expect(tree).toMatchSnapshot();
  });
});
