import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import Alert from '../alert';

describe('<Alert />', () => {
  it('should render and test snapshot', () => {
    const tree = render(<Alert showAlert />);
    expect(tree).toMatchSnapshot();
  });

  it('should render and test snapshot with hidden class', () => {
    const tree = render(<Alert showAlert={false} />);
    expect(tree).toMatchSnapshot();
  });

  it('should have div without hidden class', () => {
    const context = shallow(<Alert showAlert />);
    expect(context.find('.chatalert__default').exists()).toEqual(true);
    expect(context.find('.chatalert__default').text()).toEqual(
      'More new messages below',
    );
    expect(context.find('.chatalert__default--hidden').exists()).toEqual(false);
  });

  it('should have div with hidden class', () => {
    const context = shallow(<Alert showAlert={false} />);
    expect(context.find('.chatalert__default').exists()).toEqual(true);
    expect(context.find('.chatalert__default').text()).toEqual(
      'More new messages below',
    );
    expect(context.find('.chatalert__default--hidden').exists()).toEqual(true);
  });
});
