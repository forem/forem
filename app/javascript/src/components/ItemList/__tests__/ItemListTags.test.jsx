import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { ItemListTags } from '../ItemListTags';

describe('<ItemListTags />', () => {
  it('renders properly with two different sets of tags', () => {
    const tree = render(
      <ItemListTags
        availableTags={['discuss']}
        selectedTags={['javascript']}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('renders properly with some shared tags', () => {
    const tree = render(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('triggers the onClick', () => {
    const onClick = jest.fn();
    const context = shallow(
      <ItemListTags
        availableTags={['discuss', 'javascript']}
        selectedTags={['javascript']}
        onClick={onClick}
      />,
    );
    context.find('a').simulate('click');
    expect(onClick).toBeCalled();
  });
});
