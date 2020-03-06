import debounce from 'lodash.debounce';

/**
 * A util function to wrap any action with `debounce`.
 * To use this util, wrap it in the util like so: debounceAction(onSearchBoxType.bind(this));
 *
 * By default, this util uses a default time of 300ms, and includes a config of `{ leading: true }`,
 * which will pass the first received value to debounced function. These values can be overridden:
 * debounceAction(this.onSearchBoxType.bind(this), 150);
 *
 *
 * @param {Function} action - The function that should be wrapped with `debounce`.
 * @param {Number} [debounceTime=300] - The number of milliseconds to wait.
 * @param {Object} [debounceConfig={ leading: true }] - Any configuration for the debounce function.
 *
 * @returns {Function} A function wrapped in `debounce`.
 */
export default function debounceAction(
  action,
  debounceTime = 300,
  debounceConfig = { leading: true },
) {
  return debounce(action, debounceTime, debounceConfig);
}
