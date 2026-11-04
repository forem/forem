/**
 * A util function to wrap any action with a debounce timer.
 * To use this util, wrap it in the util like so: debounceAction(onSearchBoxType.bind(this));
 *
 * By default, this util uses a default time of 200ms, and includes a default config of `{ leading: false }`.
 * These values can be overridden: debounceAction(this.onSearchBoxType.bind(this), { time: 100, config: { leading: true }});
 *
 * @param {Function} action - The function that should be wrapped with `debounce`.
 * @param {Number} [time=200] - The number of milliseconds to wait.
 * @param {Object} [config={ leading: false }] - Any configuration for the debounce function.
 *
 * @returns {Function} A function wrapped in `debounce`.
 */
export function debounceAction(
  action,
  { time = 200, config = { leading: false } } = {},
) {
  const leading = Boolean(config?.leading);
  const trailing = config?.trailing !== undefined ? Boolean(config.trailing) : true;
  let timeoutId = null;
  let lastArgs;
  let lastThis;
  let result;

  function invoke() {
    const args = lastArgs;
    const context = lastThis;
    lastArgs = undefined;
    lastThis = undefined;
    result = action.apply(context, args);
    return result;
  }

  function debounced(...args) {
    lastArgs = args;
    lastThis = this;

    const shouldCallLeading = leading && timeoutId === null;

    if (timeoutId !== null) {
      clearTimeout(timeoutId);
    }

    timeoutId = setTimeout(() => {
      timeoutId = null;
      if (trailing && lastArgs !== undefined) {
        invoke();
      } else {
        lastArgs = undefined;
        lastThis = undefined;
      }
    }, time);

    if (shouldCallLeading) {
      lastArgs = undefined;
      lastThis = undefined;
      result = action.apply(this, args);
    }

    return result;
  }

  debounced.cancel = () => {
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
      timeoutId = null;
    }
    lastArgs = undefined;
    lastThis = undefined;
  };

  debounced.flush = () => {
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
      timeoutId = null;
      if (lastArgs !== undefined) {
        return invoke();
      }
    }
    return result;
  };

  return debounced;
}
