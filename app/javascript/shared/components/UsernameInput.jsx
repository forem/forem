import { h } from 'preact';
import PropTypes from 'prop-types';
import { MultiSelectAutocomplete } from '@crayons/MultiSelectAutocomplete/MultiSelectAutocomplete';

/**
 * UsernameInput — produces a field that can autocomplete usernames
 *
 * @param {Function} fetchSuggestions Callback to sync selections to article form state
 * @param {string} defaultValue Comma separated list of any currently user IDs
 */
export const UsernameInput = ({
  fetchSuggestions,
  defaultValue,
  inputId,
  labelText,
  placeholder,
  maxSelections,
  handleSelectionsChanged,
}) => {
  const onSelectionsChanged = function (selections) {
    const ids = selections.map((item) => item.id).join(', ');
    handleSelectionsChanged?.(ids);
  };

  return (
    <MultiSelectAutocomplete
      allowUserDefinedSelections={false}
      showLabel={false}
      border={true}
      inputId={inputId}
      labelText={labelText}
      placeholder={placeholder}
      maxSelections={maxSelections}
      defaultValue={defaultValue}
      fetchSuggestions={fetchSuggestions}
      onSelectionsChanged={onSelectionsChanged}
    />
  );
};

UsernameInput.propTypes = {
  fetchSuggestions: PropTypes.func.isRequired,
  defaultValue: PropTypes.string,
  inputId: PropTypes.string,
  labelText: PropTypes.string,
  placeholder: PropTypes.string,
  maxSelections: PropTypes.string,
  handleSelectionsChanged: PropTypes.func.isRequired,
};
