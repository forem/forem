import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import MainImage from '../mainImage';

describe('<MainImage />', () => {
  const editHandler = jest.fn();

  it('renders properly', () => {
    const tree = render(<MainImage mainImage='http://lorempixel.com/400/200/' onEdit={editHandler} />);
    expect(tree).toMatchSnapshot();
  });

  it('fires onEdit when clicked', () => {
    const container = shallow(<MainImage mainImage='http://lorempixel.com/400/200/' onEdit={editHandler} />);
    container.find('.articleform__mainimage').simulate('click');
    expect(editHandler).toHaveBeenCalled();
  });
});
