export function globalFeatureFlagEnabled(name) {
  const flags = document.body.dataset.globalFeatureFlagsEnabled || '';
  return flags.split(' ').includes(name);
}
