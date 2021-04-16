/**
 * A color input and a text input that reacts to an onColorChange change event.
 *
 * @example
 * field = {
 *  "id": 164,
 *  "attribute_name": "brand_color1",
 *  "description": "Used for backgrounds, borders etc.",
 *  "input_type": "color_field",
 *  "label": "Brand color 1",
 *  "placeholder_text": "#000000"
 * }
 * <ColorPicker
   key={field.id}
   field={field}
   onColorChange={this.handleColorPickerChange}/>

 * Note:
 * field is an json object that will contain the following attributes: attribute_name, placeholder_text, description, label.
 */

import { h } from 'preact';
import PropTypes from 'prop-types';
import { FormField } from '@crayons';

export function ColorPicker(props) {
  const { onColorChange } = props;
  const { attribute_name, placeholder_text, description, label } = props.field;

  return (
    <FormField>
      <label class="crayons-field__label" htmlFor={attribute_name}>
        {label}
      </label>
      <div class="flex items-center w-100 m:w-50">
        <input
          placeholder={placeholder_text}
          class="crayons-textfield js-color-field"
          type="text"
          name={attribute_name}
          id={attribute_name}
          onChange={onColorChange}
        />
        <input
          class="crayons-color-selector js-color-field ml-2"
          type="color"
          name={attribute_name}
          id={attribute_name}
          onChange={onColorChange}
        />
      </div>
      {description && <p class="crayons-field__description">{description}</p>}
    </FormField>
  );
}

ColorPicker.propTypes = {
  field: PropTypes.shape({
    attribute_name: PropTypes.string.isRequired,
    placeholder_text: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
  }).isRequired,
};
