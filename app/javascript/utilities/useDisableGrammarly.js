/**
 * Disable grammarly if certain conditions are met
 *
 * @returns {object|undefined} properties to disable grammarly
 *
 * @example
 * <textarea {...disabledGrammarlyProps} />
 */
export function useDisableGrammarly() {
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
