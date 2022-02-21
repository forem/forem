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

  // The third `replaceNode` argument here makes sure that the new picker is rendered in the correct position within the parentElement
  // However, Preact is unable to do a VDOM diff that allows a straight replacement of one input for the other, so we also need to remove it manually on line 29
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
