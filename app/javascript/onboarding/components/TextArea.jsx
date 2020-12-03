import PropTypes from 'prop-types';
import { FormField } from '@crayons';

const TextArea = (props) => {
  const {
    attribute_name,
    placeholder_text,
    description,
    label,
    onFieldChange,
  } = props.field;

  return (
    <FormField>
      <label class="crayons-field__label" htmlFor={attribute_name}>
        {label}
      </label>
      <textArea
        class="crayons-textfield"
        placeholder={placeholder_text}
        name={attribute_name}
        id={attribute_name}
        onChange={onFieldChange}
      />
      {description && <p class="crayons-field__description">{description}</p>}
    </FormField>
  );
};

TextArea.propTypes = {
  field: PropTypes.shape({
    attribute_name: PropTypes.string.isRequired,
    placeholder_text: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    input_type: PropTypes.string.isRequired,
  }).isRequired,
};

export default TextArea;
