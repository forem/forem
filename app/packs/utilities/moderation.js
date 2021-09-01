/**
 * Determines whether or not a member is on the moderation page.
 *
 * @param {String} [path=top.location.pathname] The path to check.
 *
 * @returns {Boolean} True if the path is the moderation page, false otherwise.
 **/
export function isModerationPage(path = top.location.pathname) {
  return path.endsWith('/mod') || path.endsWith('/mod/');
}
