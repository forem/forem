import { h } from 'preact';
import { render } from '@testing-library/preact';
import { RadioButton } from '@crayons';

describe('<RadioButton /> component', () => {
  // No a11y test here as this is just a radio button component.
  // The assumption is that it is used with a <label />

  it('should render a radio button unchecked by default', () => {
    const tree = render(<RadioButton />);
    expect(tree).toMatchSnapshot();
  });

  it('should render a radio button checked', () => {
    const { container } = render(<RadioButton checked />);
    expect(container).toMatchSnapshot();
  });

  it('should render a radio button with given props', () => {
    const { container } = render(
      <RadioButton
        id="some-id"
        value="some-value"
        name="some-name"
        className="additional-css-class-name"
        onClick={jest.fn()}
      />,
    );
    expect(container).toMatchSnapshot();
  });

  it('should support onClick', () => {
    const onClick = jest.fn();

    const { getByTestId } = render(
      <RadioButton
        id="some-id"
        value="some-value"
        name="some-name"
        className="additional-css-class-name"
        onClick={onClick}
        data-testid="radio"
      />,
    );

    const radioButton = getByTestId('radio');
    radioButton.click();

    expect(onClick).toHaveBeenCalled();
  });
});
