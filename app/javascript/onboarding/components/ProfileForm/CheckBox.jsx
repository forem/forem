/**
 * A checkbox field with a label that reacts to an onFieldChange event.

 * @example
 * field = {
 *  "id": 138,
 *  "attribute_name": "display_email_on_profile",
 *  "description": "",
 *  "input_type": "check_box",
 *  "label": "Display email on profile",
 *  "placeholder_text": ""
}
 * <CheckBox
   key={field.id}
   field={field}
   onFieldChange={this.handleFieldChange} />

 * Note:
 * field is an json object that will contain the following attributes: attribute_name, placeholder_text, description, label.
 */

import { h } from 'preact';
import PropTypes from 'prop-types';
import { FormField } from '@crayons';

export function CheckBox(props) {
  const { onFieldChange } = props;
  const { attribute_name, description, label } = props.field;

  return (
    <FormField variant="checkbox">
      <input
        class="crayons-checkbox"
        type="checkbox"
        name={attribute_name}
        id={attribute_name}
        onChange={onFieldChange}
      />
      <label class="crayons-field__label" htmlFor={attribute_name}>
        {label}
      </label>
      {description && <p class="crayons-field__description">{description}</p>}
    </FormField>
  );
}

CheckBox.propTypes = {
  field: PropTypes.shape({
    attribute_name: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    input_type: PropTypes.string.isRequired,
  }).isRequired,
};
