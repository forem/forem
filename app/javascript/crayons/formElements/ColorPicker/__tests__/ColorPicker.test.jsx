import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ColorPicker } from '@crayons';

// See this GitHub issue for a summary of the error axe raised: https://github.com/omgovich/react-colorful/issues/171.
// Although we want to see/support this being fixed, the component is still very usable for assistive technologies.
// Once this is fixed in the react-colorful lib, we can remove these custom rules.
const customAxeRules = {
  'aria-required-attr': { enabled: false },
};

describe('<ColorPicker />', () => {
  it('should have no a11y violations when rendered', async () => {
    const { container } = render(
      <ColorPicker
        id="color-picker"
        buttonLabelText="Choose a color"
        inputProps={{ 'aria-label': 'Choose a color' }}
      />,
    );

    const results = await axe(container, { rules: customAxeRules });
    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { container } = render(
      <ColorPicker
        id="color-picker"
        buttonLabelText="Choose a color"
        inputProps={{ 'aria-label': 'Choose a color' }}
      />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render with a default value', () => {
    const { container } = render(
      <ColorPicker
        id="color-picker"
        buttonLabelText="Choose a color"
        defaultValue="#ababab"
        inputProps={{ 'aria-label': 'Choose a color' }}
      />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('converts 3 char hex codes to full 6 chars on blur', async () => {
    const changeHandler = jest.fn();

    const { getByRole } = render(
      <ColorPicker
        id="color-picker"
        buttonLabelText="Choose a color"
        defaultValue="#0B6"
        inputProps={{ 'aria-label': 'Choose a color' }}
        onChange={changeHandler}
      />,
    );

    const input = getByRole('textbox', { name: 'Choose a color' });
    input.focus();
    input.blur();

    await waitFor(() => expect(changeHandler).toHaveBeenCalledWith('#00BB66'));
  });
});
