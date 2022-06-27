// import { replaceTextInputWithColorPicker } from '../colorPickers/replaceTextInputWithColorPicker';
import { h, render } from 'preact';
import { MultiSelectAutocomplete } from '@crayons';

// Find any multiselect inputs on the page and replace them with the Preact enhanced component
const multiselects = document.querySelectorAll('[data-multi-select-autocomplete]');

function replaceTextInputWithMultiselectAutocomplete({input}) {
  console.log("Asked to replace", input)
  const inputProps = {};

  // Copy any specific attributes to the new input
  const { attributes: inputAttributes } = input;
  for (const attr of inputAttributes) {
    inputProps[attr.name] = attr.value;
  }

  // The third `replaceNode` argument here makes sure that the new picker is rendered in the correct position within the parentElement
  // However, Preact is unable to do a VDOM diff that allows a straight replacement of one input for the other, so we also need to remove it manually below
  render(
    <MultiSelectAutocomplete
      border
      fetchSuggestions={() => {}}
      labelText="Member"
      maxSelections={1}
      placeholder="Assign this template to a specific member"
      showLabel
      staticSuggestions={[
        {
          name: 'Alvin'
        },
        {
          name: 'Simon'
        },
        {
          name: 'Theodore'
        }
      ]}
      staticSuggestionsHeading="Static suggestions"
    />,
    input.parentElement,
    input,
  );
  input.remove();
}


// function replaceTextInputWithMultiselectAutocomplete(input, dataSet) {
//   console.log("REPLACE!!", input, dataSet)
// }

for (const input of multiselects) {
  const { dataSet } = input.dataset;
  replaceTextInputWithMultiselectAutocomplete({ input, dataSet });
}

console.log("LOADED")
