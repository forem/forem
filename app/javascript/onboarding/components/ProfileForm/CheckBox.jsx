import { h } from 'preact';
import PropTypes from 'prop-types';
import { FormField } from '@crayons';

const CheckBox = (props) => {
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
};

CheckBox.propTypes = {
  field: PropTypes.shape({
    attribute_name: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    input_type: PropTypes.string.isRequired,
  }).isRequired,
};

export default CheckBox;
