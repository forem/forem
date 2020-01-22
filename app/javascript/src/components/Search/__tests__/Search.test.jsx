import { h } from 'preact';
import { render } from 'preact-render-to-string';
import { Search } from '../Search';

describe('<Search />', () => {
  beforeEach(() => {
    global.filterXSS = x => x;
  });

  afterEach(() => {
    global.filterXSS = undefined;
  });

  it('renders properly', () => {
    const tree = render(<Search />);
    expect(tree).toMatchSnapshot();
  });
});
