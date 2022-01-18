import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ButtonNew as Button } from '@crayons';
import CogIcon from '@images/cog.svg';
import '@testing-library/jest-dom';

describe('<Button />', () => {
  it('has no accessibility errors in default variant', async () => {
    const { container } = render(<Button>Hello world!</Button>);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has no accessibility errors in primary variant', async () => {
    const { container } = render(
      <Button variant="primary">Hello world!</Button>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has no accessibility errors in secondary variant', async () => {
    const { container } = render(
      <Button variant="secondary">Hello world!</Button>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has no accessibility errors when props provided', async () => {
    const { container } = render(
      <Button
        variant="primary"
        rounded
        destructive
        icon={CogIcon}
        tooltip="tooltip"
      >
        Hello world!
      </Button>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders a default button', () => {
    const { container } = render(<Button>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a primary button', () => {
    const { container } = render(
      <Button variant="primary">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a secondary button', () => {
    const { container } = render(
      <Button variant="secondary">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with an icon and text', () => {
    const { container } = render(<Button icon={CogIcon}>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with an icon only', () => {
    const { container } = render(<Button icon={CogIcon} />);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a destructive button', () => {
    const { container } = render(<Button destructive>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a rounded button', () => {
    const { container } = render(<Button rounded>Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with a tooltip', () => {
    const { container } = render(
      <Button tooltip="tooltip text">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with additional classnames', () => {
    const { container } = render(
      <Button className="one two three">Hello world!</Button>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a button as a specific button type (HTML type attribute) when buttonType is set.', () => {
    const { container } = render(<Button type="submit">Hello world!</Button>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should attach additional passed props to the button element', () => {
    const mockClickHandler = jest.fn();

    const { getByRole } = render(
      <Button onClick={mockClickHandler}>Hello world!</Button>,
    );

    const button = getByRole('button', { name: 'Hello world!' });
    button.click();

    expect(mockClickHandler).toHaveBeenCalledTimes(1);
  });

  it('should suppress any tooltip and execute any onKeyUp prop when Escape is pressed', async () => {
    const mockKeyUpHandler = jest.fn();

    const { getByRole, getByTestId } = render(
      <Button tooltip="test tooltip" onKeyUp={mockKeyUpHandler}>
        Hello world!
      </Button>,
    );

    const button = getByRole('button', { name: 'Hello world! test tooltip' });
    button.focus();

    expect(getByTestId('tooltip')).not.toHaveClass(
      'crayons-tooltip__suppressed',
    );

    fireEvent.keyUp(button, { key: 'Escape' });

    expect(getByTestId('tooltip')).toHaveClass('crayons-tooltip__suppressed');
    expect(mockKeyUpHandler).toHaveBeenCalledTimes(1);
  });
});
