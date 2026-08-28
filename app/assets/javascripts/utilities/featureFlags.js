// Sprockets-side twin of app/javascript/utilities/featureFlags.js
function globalFeatureFlagEnabled(name) {
  const flags = document.body.dataset.globalFeatureFlagsEnabled || '';
  return flags.split(' ').includes(name);
}
