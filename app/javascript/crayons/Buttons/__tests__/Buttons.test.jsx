import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ButtonNew } from '@crayons';
import CogIcon from '@images/cog.svg';
import '@testing-library/jest-dom';

describe('<ButtonNew />', () => {
  it('has no accessibility errors in default variant', async () => {
    const { container } = render(<ButtonNew>Hello world!</ButtonNew>);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has no accessibility errors when props provided', async () => {
    const { container } = render(
      <ButtonNew primary rounded destructive icon={CogIcon} tooltip="tooltip">
        Hello world!
      </ButtonNew>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders a default button', () => {
    const { container } = render(<ButtonNew>Hello world!</ButtonNew>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a primary button', () => {
    const { container } = render(<ButtonNew primary>Hello world!</ButtonNew>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with an icon and text', () => {
    const { container } = render(
      <ButtonNew icon={CogIcon}>Hello world!</ButtonNew>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with an icon only', () => {
    const { container } = render(<ButtonNew icon={CogIcon} />);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a destructive button', () => {
    const { container } = render(
      <ButtonNew destructive>Hello world!</ButtonNew>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders a rounded button', () => {
    const { container } = render(<ButtonNew rounded>Hello world!</ButtonNew>);
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with a tooltip', () => {
    const { container } = render(
      <ButtonNew tooltip="tooltip text">Hello world!</ButtonNew>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with additional classnames', () => {
    const { container } = render(
      <ButtonNew className="one two three">Hello world!</ButtonNew>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render a button as a specific button type (HTML type attribute) when buttonType is set.', () => {
    const { container } = render(
      <ButtonNew type="submit">Hello world!</ButtonNew>,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should attach additional passed props to the button element', () => {
    const mockClickHandler = jest.fn();

    const { getByRole } = render(
      <ButtonNew onClick={mockClickHandler}>Hello world!</ButtonNew>,
    );

    const button = getByRole('button', { name: 'Hello world!' });
    button.click();

    expect(mockClickHandler).toHaveBeenCalledTimes(1);
  });

  it('should suppress any tooltip and execute any onKeyUp prop when Escape is pressed', async () => {
    const mockKeyUpHandler = jest.fn();

    const { getByRole, getByTestId } = render(
      <ButtonNew tooltip="test tooltip" onKeyUp={mockKeyUpHandler}>
        Hello world!
      </ButtonNew>,
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
