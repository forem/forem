import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { RadioButton } from '@crayons';

describe('<RadioButton /> component', () => {
  it('should render a radio button unchecked by default', () => {
    const tree = render(<RadioButton />);
    expect(tree).toMatchSnapshot();
  });

  it('should render a radio button checked', () => {
    const tree = render(<RadioButton checked />);
    expect(tree).toMatchSnapshot();
  });

  it('should render a radio button with given props', () => {
    const tree = render(
      <RadioButton
        id="some-id"
        value="some-value"
        name="some-name"
        className="additional-css-class-name"
        onClick={jest.fn()}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should support onClick', () => {
    const onClick = jest.fn();

    const wrapper = shallow(
      <RadioButton
        id="some-id"
        value="some-value"
        name="some-name"
        className="additional-css-class-name"
        onClick={onClick}
      />,
    );

    wrapper.simulate('click');

    expect(onClick).toHaveBeenCalled();
  });
});
