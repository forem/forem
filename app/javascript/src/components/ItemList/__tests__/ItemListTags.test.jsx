import { h } from 'preact';
import render from 'preact-render-to-json';
import { ItemListTags } from '../ItemListTags';

describe('<ItemListTags />', () => {
  it('renders properly', () => {
    const tree = render(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
