import debounce from 'lodash.debounce';

/**
 * A util function to wrap any action with lodash's `debounce` (https://lodash.com/docs/#debounce).
 * To use this util, wrap it in the util like so: debounceAction(onSearchBoxType.bind(this));
 *
 * By default, this util uses a default time of 300ms, and includes a default config of `{ leading: false }`.
 * These values can be overridden: debounceAction(this.onSearchBoxType.bind(this), { time: 100, config: { leading: true }});
 *
 *
 * @param {Function} action - The function that should be wrapped with `debounce`.
 * @param {Number} [time=300] - The number of milliseconds to wait.
 * @param {Object} [config={ leading: false }] - Any configuration for the debounce function.
 *
 * @returns {Function} A function wrapped in `debounce`.
 */
export function debounceAction(
  action,
  { time = 300, config = { leading: false } } = {},
) {
  const configs = { ...config };
  return debounce(action, time, configs);
}
