/**
 * Get the textarea attributes required to disable the Grammarly browser extension in Chrome browsers
 * This is a temporary "fix" to get around this issue: https://github.com/forem/forem/issues/13814
 *
 * @returns {object|undefined} properties to disable grammarly
 *
 * @example
 * <textarea {...disabledGrammarlyProps} />
 */
export function useDisableGrammarlyInChrome() {
  // 🚑 Detect if user is using chromium to disable grammarly
  const isChrome =
    !!window.chrome &&
    !(navigator.userAgent.toLowerCase().indexOf('edg/') > -1);

  return isChrome
    ? {
        'data-gramm_editor': 'false',
      }
    : null;
}
