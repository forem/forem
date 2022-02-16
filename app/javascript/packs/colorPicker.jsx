import { h, render } from 'preact';
import { ColorPicker } from '@crayons';

// Find any color picker inputs on the page and replace them with the Preact enhanced component
const colorInputs = document.querySelectorAll('[data-color-picker]');

for (const input of colorInputs) {
  const { labelText } = input.dataset;
  const inputProps = {};

  // Copy any specific attributes to the new input
  const { attributes: inputAttributes } = input;
  for (const attr of inputAttributes) {
    inputProps[attr.name] = attr.value;
  }

  render(
    <ColorPicker
      id={inputProps.id}
      defaultValue={input.value}
      inputProps={inputProps}
      buttonLabelText={labelText}
    />,
    input.parentElement,
    input,
  );
  input.remove();
}
