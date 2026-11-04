/**
 * Strips HTML comments and escapes `<` and `>` characters to prevent XSS.
 *
 * Historically this file bundled the full `xss` + `cssfilter` browserify bundle
 * (1,573 lines / ~49 KB) with an empty tag allowlist (`getDefaultWhiteList() => {}`),
 * which meant all tag/attribute/CSS-property parsing was unreachable dead code that
 * ultimately stripped `<!-- ... -->` comments and escaped `<` / `>`.
 *
 * @param {string} html Input string to sanitize
 * @returns {string} Escaped string safe for HTML insertion
 */
function filterXSS(html) {
  html = html || '';
  html = html.toString();
  if (!html) return '';
  return html
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

if (typeof exports !== 'undefined') {
  if (typeof module !== 'undefined' && module.exports) {
    exports = module.exports = filterXSS;
  }
  exports.filterXSS = filterXSS;
}

if (typeof window !== 'undefined') {
  window.filterXSS = filterXSS;
}
