import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { ItemListItemArchiveButton } from '../ItemListItemArchiveButton';

describe('<ItemListItemArchiveButton />', () => {
  it('renders properly', () => {
    const tree = render(<ItemListItemArchiveButton text="archive" />);
    expect(tree).toMatchSnapshot();
  });

  it('triggers the onClick if the Enter key is pressed', () => {
    const onClick = jest.fn();
    const context = shallow(
      <ItemListItemArchiveButton text="archive" onClick={onClick} />,
    );
    context.find('a').simulate('keyup', { key: 'Enter' });
    expect(onClick).toBeCalled();
  });
});
