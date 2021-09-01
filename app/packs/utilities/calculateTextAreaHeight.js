// These styles are applied to the hidden element we use to measure the height.
// !important styles are used to ensure no matter what style properties are attached to the given textarea, the hidden textarea will never become visible or cause layout jumps
const HIDDEN_TEXTAREA_STYLE = `
min-height:0 !important;
max-height:none !important;
height:0 !important;
visibility:hidden !important;
overflow:hidden !important;
position:absolute !important;
z-index:-1000 !important;
top:0 !important;
right:0 !important
`;

const SIZING_STYLE = [
  'letter-spacing',
  'line-height',
  'padding-top',
  'padding-bottom',
  'font-family',
  'font-weight',
  'font-size',
  'text-rendering',
  'text-transform',
  'width',
  'text-indent',
  'padding-left',
  'padding-right',
  'border-width',
  'box-sizing',
];

let hiddenTextarea;

/**
 * Helper function to get the height of the textarea based on the current text content
 *
 * @param {HTMLElement} uiTextNode The textarea to measure height of
 *
 * @returns {{height: number}} Object with the calculated height
 */
export const calculateTextAreaHeight = (uiTextNode) => {
  if (!hiddenTextarea) {
    hiddenTextarea = document.createElement('textarea');
    document.body.appendChild(hiddenTextarea);
  }

  // Copy all CSS properties that have an impact on the height of the content in
  // the textbox
  const {
    paddingSize,
    borderSize,
    boxSizing,
    sizingStyle,
  } = calculateNodeStyling(uiTextNode);

  // Need to have the overflow attribute to hide the scrollbar otherwise
  // text-lines will not calculated properly as the shadow will technically be
  // narrower for content
  hiddenTextarea.setAttribute(
    'style',
    `${sizingStyle};${HIDDEN_TEXTAREA_STYLE}`,
  );
  hiddenTextarea.value = uiTextNode.value || uiTextNode.placeholder || 'x';

  const baseHeight = hiddenTextarea.scrollHeight;

  if (boxSizing === 'border-box') {
    // border-box: add border, since height = content + padding + border
    return { height: baseHeight + borderSize };
  } else if (boxSizing === 'content-box') {
    // remove padding, since height = content
    return { height: baseHeight - paddingSize };
  }

  return { height: baseHeight };
};

const calculateNodeStyling = (node) => {
  const style = window.getComputedStyle(node);

  const boxSizing =
    style.getPropertyValue('box-sizing') ||
    style.getPropertyValue('-moz-box-sizing') ||
    style.getPropertyValue('-webkit-box-sizing');

  const paddingSize =
    parseFloat(style.getPropertyValue('padding-bottom')) +
    parseFloat(style.getPropertyValue('padding-top'));

  const borderSize =
    parseFloat(style.getPropertyValue('border-bottom-width')) +
    parseFloat(style.getPropertyValue('border-top-width'));

  const sizingStyle = SIZING_STYLE.map(
    (name) => `${name}:${style.getPropertyValue(name)}`,
  ).join(';');

  return {
    sizingStyle,
    paddingSize,
    borderSize,
    boxSizing,
  };
};
