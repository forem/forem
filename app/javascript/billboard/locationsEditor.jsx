import { h } from 'preact';
import { useCallback, useMemo } from 'preact/hooks';
import PropTypes from 'prop-types';
import { MultiSelectAutocomplete } from '@crayons';

export const LocationsEditor = ({ defaultValue = {}, locations }) => {
  const autocompleteLocations = useCallback((_query) => locations, [locations]);
  const defaultSelections = useMemo(
    () => Object.keys(defaultValue),
    [defaultValue],
  );

  return (
    <MultiSelectAutocomplete
      defaultValue={defaultSelections}
      fetchSuggestions={autocompleteLocations}
      border
      showLabel={false}
      inputId="billboard-enabled-countries-editor"
      allowUserDefinedSelections={false}
    />
  );
};

LocationsEditor.propTypes = {
  defaultValue: PropTypes.objectOf(PropTypes.oneOf([true, 'with_regions'])),
  locations: PropTypes.objectOf(PropTypes.string).isRequired,
};
