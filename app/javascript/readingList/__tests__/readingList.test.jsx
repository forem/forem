import { h } from 'preact';
import render from 'preact-render-to-json';
import { ReadingList } from '../readingList';

describe('<ReadingList />', () => {
  it('renders properly', () => {
    const tree = render(<ReadingList availableTags={['discuss']} />);
    expect(tree).toMatchSnapshot();
  });
});
