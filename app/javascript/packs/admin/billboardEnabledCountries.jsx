import { h, render } from 'preact';
import { Locations, SelectedLocation } from '../../billboard/locations';

const RegionMarker = ({ withRegions }) => {
  return (
    <span className="fs-xs fw-bold">
      {withRegions ? 'Including' : 'Excluding'} regions
    </span>
  );
};

function parseDOMState(hiddenField) {
  const countriesByCode = JSON.parse(hiddenField.dataset.allCountries);

  const allCountries = {};
  for (const [code, name] of Object.entries(countriesByCode)) {
    allCountries[name] = { name, code };
  }
  const existingSetting = JSON.parse(hiddenField.value);
  const selectedCountries = Object.keys(existingSetting).map((code) => ({
    name: countriesByCode[code],
    code,
    withRegions: existingSetting[code] === 'with_regions',
  }));

  return { allCountries, selectedCountries };
}

function syncSelectionsToDOM(hiddenField, countries) {
  const newValue = countries.reduce((value, { code, withRegions }) => {
    value[code] = withRegions ? 'with_regions' : 'without_regions';
    return value;
  }, {});
  hiddenField.value = JSON.stringify(newValue);
}

/**
 * Sets up and renders a Preact component to handle searching for and enabling
 * countries for targeting (and, per country, to enable region-level targeting).
 */
function setupEnabledCountriesEditor() {
  const editor = document.getElementById('billboard-enabled-countries-editor');
  const hiddenField = document.querySelector('.geolocation-multiselect');

  if (!(editor && hiddenField)) return;

  const { allCountries, selectedCountries } = parseDOMState(hiddenField);
  let currentSelections = selectedCountries;

  function setCountriesSelection(countries) {
    currentSelections = countries;
    syncSelectionsToDOM(hiddenField, currentSelections);
  }

  function updateRegionSetting(country) {
    const selected = currentSelections.find(
      (selectedCountry) => selectedCountry.code === country.code,
    );
    selected.withRegions = !selected.withRegions;
    syncSelectionsToDOM(hiddenField, currentSelections);
    renderLocations();
  }

  const EnabledCountry = SelectedLocation({
    displayName: 'EnabledCountry',
    onNameClick: updateRegionSetting,
    label: 'Toggle region targeting',
    ExtraInfo: RegionMarker,
  });

  function renderLocations() {
    render(
      <Locations
        defaultValue={currentSelections}
        onChange={setCountriesSelection}
        inputId="billboard-enabled-countries-editor"
        allLocations={allCountries}
        template={EnabledCountry}
      />,
      editor,
    );
  }

  renderLocations();
}

if (document.readyState !== 'loading') {
  setupEnabledCountriesEditor();
} else {
  document.addEventListener('DOMContentLoaded', setupEnabledCountriesEditor);
}
