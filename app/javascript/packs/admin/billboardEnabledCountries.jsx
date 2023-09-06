import { h, render } from 'preact';
import { Locations, SelectedLocation } from '../../billboard/locations';

const RegionMarker = ({ withRegions }) => {
  return <span>Region targeting {withRegions ? 'enabled' : 'disabled'}</span>;
};

function setCountriesSelection(countries) {
  const hiddenField = document.querySelector('.geolocation-multiselect');

  if (hiddenField) {
    const newValue = countries.reduce((value, { code, withRegions }) => {
      value[code] = withRegions ? 'with_regions' : 'without_regions';
      return value;
    }, {});
    hiddenField.value = JSON.stringify(newValue);
  }
}

function updateSingleCountry({ code, withRegions }) {
  const hiddenField = document.querySelector('.geolocation-multiselect');

  if (hiddenField) {
    const value = JSON.parse(hiddenField.value);
    value[code] = withRegions ? 'with_regions' : 'without_regions';
    hiddenField.value = JSON.stringify(value);
  }
}

/**
 * Sets up and renders a Preact component to handle searching for and enabling
 * countries for targeting (and, per country, to enable region-level targeting).
 */
function setupEnabledCountriesEditor() {
  const editor = document.getElementById('billboard-enabled-countries-editor');
  const hiddenField = document.querySelector('.geolocation-multiselect');

  if (!(editor && hiddenField)) return;

  const countriesByCode = JSON.parse(hiddenField.dataset.allCountries);
  const existingSetting = JSON.parse(hiddenField.value);

  const allCountries = {};
  for (const [code, name] of Object.entries(countriesByCode)) {
    allCountries[name] = { name, code };
  }
  const selectedCountries = Object.keys(existingSetting).map((code) => ({
    name: countriesByCode[code],
    code,
    withRegions: existingSetting[code] === 'with_regions',
  }));
  const EnabledCountry = SelectedLocation({
    displayName: 'EnabledCountry',
    onClick: updateSingleCountry,
    label: 'Toggle region targeting',
    ExtraInfo: RegionMarker,
  });

  render(
    <Locations
      defaultValue={selectedCountries}
      onChange={setCountriesSelection}
      inputId="billboard-enabled-countries-editor"
      allLocations={allCountries}
      template={EnabledCountry}
    />,
    editor,
  );
}

if (document.readyState !== 'loading') {
  setupEnabledCountriesEditor();
} else {
  document.addEventListener('DOMContentLoaded', setupEnabledCountriesEditor);
}
