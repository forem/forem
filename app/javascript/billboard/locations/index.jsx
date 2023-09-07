import { h } from 'preact';
import { useCallback } from 'preact/hooks';
import PropTypes from 'prop-types';
import { MultiSelectAutocomplete } from '@crayons';

export { SelectedLocation } from './templates';

export const Locations = ({
  defaultValue = [],
  allLocations,
  inputId,
  onChange,
  placeholder = 'Enter a country name...',
  template,
}) => {
  const autocompleteLocations = useCallback(
    (query) => {
      return new Promise((resolve) => {
        queueMicrotask(() => {
          const suggestions = [];
          Object.keys(allLocations).forEach((name) => {
            if (name.indexOf(query) > -1) {
              suggestions.push(allLocations[name]);
            }
          });
          resolve(suggestions);
        });
      });
    },
    [allLocations],
  );

  return (
    <MultiSelectAutocomplete
      defaultValue={defaultValue}
      fetchSuggestions={autocompleteLocations}
      border
      // The label is already part of the page!
      showLabel={false}
      labelText=""
      placeholder={placeholder}
      SelectionTemplate={template}
      onSelectionsChanged={onChange}
      inputId={inputId}
      allowUserDefinedSelections={false}
    />
  );
};

const locationsShape = PropTypes.shape({
  name: PropTypes.string.isRequired,
  code: PropTypes.string.isRequired,
  withRegions: PropTypes.bool,
});

Locations.propTypes = {
  defaultValue: PropTypes.arrayOf(locationsShape),
  allLocations: PropTypes.objectOf(locationsShape).isRequired,
  inputId: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  placeholder: PropTypes.string,
  template: PropTypes.elementType,
};
