import { h, render } from 'preact';
import { createRootFragment } from '../shared/preact/preact-root-fragment';
import { ColorPicker } from '@crayons';

/**
 * Takes a text input, and replaces it with the richer Preact component
 *
 * @param {HTMLElement} input The input to replace
 * @param {string} labelText The label to apply to the new form controls
 * @param {function} onChange Any onChange callback
 */
export function replaceTextInputWithColorPicker({
  input,
  labelText,
  onChange,
}) {
  const inputProps = {};

  // Copy any specific attributes to the new input
  const { attributes: inputAttributes } = input;
  for (const attr of inputAttributes) {
    inputProps[attr.name] = attr.value;
  }

  // The third `replaceNode` argument here makes sure that the new picker is rendered in the correct position within the parentElement
  // However, Preact is unable to do a VDOM diff that allows a straight replacement of one input for the other, so we also need to remove it manually below
  render(
    <ColorPicker
      id={inputProps.id}
      defaultValue={input.value}
      inputProps={inputProps}
      buttonLabelText={labelText}
      onChange={onChange}
    />,
    createRootFragment(input.parentElement, input),
  );
  input.remove();
}
