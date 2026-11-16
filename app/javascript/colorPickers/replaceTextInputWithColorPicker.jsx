import { h, render } from 'preact';
import { createRootFragment } from '../shared/preact/preact-root-fragment';
import { ColorPicker } from '@crayons';

const ALLOWED_PREVIEW_PROPERTIES = new Set(['backgroundColor', 'fill']);
const HEX_COLOR_PATTERN = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;
const DEFAULT_BG_FALLBACK = '#0a0a0a';
const DEFAULT_TEXT_FALLBACK = '#ffffff';

function syncPreviewLogoStyles(previewLogo) {
  const defaultBgColor =
    previewLogo.dataset.defaultBgColor || DEFAULT_BG_FALLBACK;
  const defaultTextColor =
    previewLogo.dataset.defaultTextColor || DEFAULT_TEXT_FALLBACK;
  const currentBgColor = previewLogo.dataset.currentBgColor || '';
  const currentTextColor = previewLogo.dataset.currentTextColor || '';

  if (currentBgColor === '') {
    previewLogo.style.backgroundColor = defaultBgColor;
    previewLogo.style.fill = defaultTextColor;
  } else {
    previewLogo.style.backgroundColor = currentBgColor;
    previewLogo.style.fill = currentTextColor || defaultTextColor;
  }
}

/**
 * Builds an onChange callback that updates #color-select-preview-logo when the
 * enhanced input specifies a valid data-preview-property attribute.
 *
 * @param {HTMLElement} input The original text input
 * @returns {function|undefined}
 */
export function createPreviewChangeHandler(input) {
  const previewProperty = input?.dataset?.previewProperty;
  if (!ALLOWED_PREVIEW_PROPERTIES.has(previewProperty)) {
    return undefined;
  }

  const datasetKey =
    previewProperty === 'backgroundColor'
      ? 'currentBgColor'
      : 'currentTextColor';

  const applyPreviewColor = (value) => {
    const previewLogo = document.getElementById('color-select-preview-logo');
    if (!previewLogo) {
      return;
    }

    if (value === '') {
      previewLogo.dataset[datasetKey] = '';
    } else if (HEX_COLOR_PATTERN.test(value)) {
      previewLogo.dataset[datasetKey] = value;
    } else {
      return;
    }

    syncPreviewLogoStyles(previewLogo);
  };

  applyPreviewColor(input.value || '');
  return applyPreviewColor;
}

/**
 * Takes a text input, and replaces it with the richer Preact component
 *
 * @param {HTMLElement} input The input to replace
 * @param {string} labelText The label to apply to the new form controls
 * @param {function} onChange Any onChange callback
 */
export function replaceTextInputWithColorPicker({
  input,
  labelText,
  onChange = createPreviewChangeHandler(input),
}) {
  const inputProps = {};

  // Copy any specific attributes to the new input
  const { attributes: inputAttributes } = input;
  for (const attr of inputAttributes) {
    inputProps[attr.name] = attr.value;
  }

  // The third `replaceNode` argument here makes sure that the new picker is rendered in the correct position within the parentElement
  // However, Preact is unable to do a VDOM diff that allows a straight replacement of one input for the other, so we also need to remove it manually below
  render(
    <ColorPicker
      id={inputProps.id}
      defaultValue={input.value}
      inputProps={inputProps}
      buttonLabelText={labelText}
      onChange={onChange}
    />,
    createRootFragment(input.parentElement, input),
  );
  input.remove();
}
