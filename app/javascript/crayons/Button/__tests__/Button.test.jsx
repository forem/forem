import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Button } from '@crayons';

describe('<Button /> component', () => {
  it('should have no a11y violations when rendered', async () => {
    const { container } = render(<Button>Hello world!</Button>);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render a primary button when using default values', () => {
    const { container } = render(<Button>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render with a tabIndex', () => {
    const { container } = render(<Button tabIndex="0">Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a secondary button when using the variant "secondary"', () => {
    const { container } = render(
      <Button variant="secondary">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render an outlined button when using the variant "outlined"', () => {
    const { container } = render(
      <Button variant="outlined">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a danger button when using the variant "danger"', () => {
    const { container } = render(
      <Button variant="danger">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render an enabled button when using default values', () => {
    const { container } = render(<Button>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a disabled button when disabled is true', () => {
    const { container } = render(<Button disabled>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a button with additional CSS classes when className is set', () => {
    const { container } = render(
      <Button disabled className="some-additional-class-name">
        Hello world!
      </Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
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

    const { container } = render(
      <Button icon={Icon} contentType="icon-left">
        Hello world!
      </Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
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

    const { container } = render(<Button icon={Icon} contentType="icon" />);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a button as an anchor element if "tagName" is set to "a"', () => {
    const { container } = render(
      <Button tagName="a" url="https://dev.to">
        Hello world!
      </Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a button as a specific button type (HTML type attribute) when buttonType is set.', () => {
    const { container } = render(
      <Button buttonType="submit">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should fire the onClick event when the button is clicked.', () => {
    const someEvent = jest.fn();

    const { getByText } = render(
      <Button onClick={someEvent}>Hello world!</Button>,
    );

    const button = getByText('Hello world!');
    button.click();

    expect(someEvent).toHaveBeenCalledTimes(1);
  });

  it('should fire the onMouseOver event when the button is moused over.', () => {
    const someEvent = jest.fn();

    const { getByText } = render(
      <Button onMouseOver={someEvent} onfocus={jest.fn()}>
        Hello world!
      </Button>,
    );

    const button = getByText('Hello world!');
    fireEvent.mouseOver(button);

    expect(someEvent).toHaveBeenCalledTimes(1);
  });

  it('should fire the onMouseOut event when the button is moused out.', () => {
    const someEvent = jest.fn();

    const { getByText } = render(
      <Button onMouseOut={someEvent} onBlur={jest.fn()}>
        Hello world!
      </Button>,
    );
    const button = getByText('Hello world!');
    fireEvent.mouseOut(button);

    expect(someEvent).toHaveBeenCalledTimes(1);
  });

  it('should fire the onFocus event when the button is given focus.', () => {
    const someEvent = jest.fn();

    const { getByText } = render(
      <Button onFocus={someEvent}>Hello world!</Button>,
    );

    const button = getByText('Hello world!');
    button.focus();

    expect(someEvent).toHaveBeenCalledTimes(1);
  });

  it('should fire the onBlur event when the button loses focus.', () => {
    const someEvent = jest.fn();

    const { getByText } = render(
      <Button onBlur={someEvent}>Hello world!</Button>,
    );

    const button = getByText('Hello world!');
    button.focus();
    button.blur();

    expect(someEvent).toHaveBeenCalledTimes(1);
  });

  it('should render with a tooltip', () => {
    const { container } = render(
      <Button tooltip="tooltip text">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });
});
