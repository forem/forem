import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { Button } from '@crayons';

describe('<Button /> component', () => {
  it('should render a primary button when using default values', () => {
    const tree = render(<Button>Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render a secondary button when using the variant "secondary"', () => {
    const tree = render(<Button variant="secondary">Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render an outlined button when using the variant "outlined"', () => {
    const tree = render(<Button variant="outlined">Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render a danger button when using the variant "danger"', () => {
    const tree = render(<Button variant="danger">Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render an enabled button when using default values', () => {
    const tree = render(<Button>Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render a disabled button when disabled is true', () => {
    const tree = render(<Button disabled>Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render a button with addtional CSS classes when className is set', () => {
    const tree = render(
      <Button disabled className="some-additional-class-name">
        Hello world!
      </Button>,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a button with with an icon when an icon is set and there is button text', () => {
    const Icon = () => (
      <svg
        width="24"
        height="24"
        xmlns="http://www.w3.org/2000/svg"
        className="crayons-icon"
      >
        <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
      </svg>
    );

    const tree = render(<Button icon={Icon}>Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should render a button with with an icon when an icon is set and there is no button text', () => {
    const Icon = () => (
      <svg
        width="24"
        height="24"
        xmlns="http://www.w3.org/2000/svg"
        className="crayons-icon"
      >
        <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
      </svg>
    );

    const tree = render(<Button icon={Icon} />);
    expect(tree).toMatchSnapshot();
  });

  it('should render a button as an anchor element if "tagName" is set to "a"', () => {
    const tree = render(
      <Button tagName="a" url="https://dev.to">
        Hello world!
      </Button>,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a button as a specific button type (HTML type attribute) when buttonType is set.', () => {
    const tree = render(<Button buttonType="submit">Hello world!</Button>);
    expect(tree).toMatchSnapshot();
  });

  it('should fire the onClick event when the button is clicked.', () => {
    const someEvent = jest.fn();

    shallow(<Button onClick={someEvent}>Hello world!</Button>)
      .find('button')
      .simulate('click');

    expect(someEvent).toHaveBeenCalled();
  });

  it('should fire the onMouseOver event when the button is moused over.', () => {
    const someEvent = jest.fn();

    shallow(
      <Button onMouseOver={someEvent} onfocus={jest.fn()}>
        Hello world!
      </Button>,
    )
      .find('button')
      .simulate('mouseover');

    expect(someEvent).toHaveBeenCalled();
  });

  it('should fire the onMouseOut event when the button is moused out.', () => {
    const someEvent = jest.fn();

    shallow(
      <Button onMouseOut={someEvent} onBlur={jest.fn()}>
        Hello world!
      </Button>,
    )
      .find('button')
      .simulate('mouseout');

    expect(someEvent).toHaveBeenCalled();
  });

  it('should fire the onFocus event when the button is given focus.', () => {
    const someEvent = jest.fn();

    shallow(<Button onFocus={someEvent}>Hello world!</Button>)
      .find('button')
      .simulate('focus');

    expect(someEvent).toHaveBeenCalled();
  });

  it('should fire the onBlur event when the button loses focus.', () => {
    const someEvent = jest.fn();

    shallow(<Button onBlur={someEvent}>Hello world!</Button>)
      .find('button')
      .simulate('blur');

    expect(someEvent).toHaveBeenCalled();
  });
});
