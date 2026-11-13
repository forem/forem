import { fireEvent, screen } from '@testing-library/preact';
import { replaceTextInputWithColorPicker } from '../replaceTextInputWithColorPicker';

describe('replaceTextInputWithColorPicker', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div>
        <div id="bg-field">
          <input
            id="organization_bg_color_hex"
            type="text"
            value="#e036c4"
            placeholder="#000000"
            data-color-picker="true"
            data-label-text="Brand color 1"
            data-preview-property="backgroundColor"
            aria-label="Brand color 1"
          />
        </div>
        <div id="text-field">
          <input
            id="organization_text_color_hex"
            type="text"
            value="#12ff00"
            placeholder="#ffffff"
            data-color-picker="true"
            data-label-text="Brand color 2"
            data-preview-property="fill"
            aria-label="Brand color 2"
          />
        </div>
        <svg id="color-select-preview-logo"></svg>
      </div>
    `;
  });

  it('initializes and live-updates #color-select-preview-logo backgroundColor and fill', () => {
    const bgInput = document.getElementById('organization_bg_color_hex');
    const textInput = document.getElementById('organization_text_color_hex');
    const previewLogo = document.getElementById('color-select-preview-logo');

    replaceTextInputWithColorPicker({
      input: bgInput,
      labelText: bgInput.dataset.labelText,
    });
    replaceTextInputWithColorPicker({
      input: textInput,
      labelText: textInput.dataset.labelText,
    });

    expect(previewLogo.style.backgroundColor).toBe('rgb(224, 54, 196)');
    expect(previewLogo.style.fill).toBe('#12ff00');

    const enhancedBgInput = screen.getByRole('textbox', {
      name: 'Brand color 1',
    });
    const enhancedTextInput = screen.getByRole('textbox', {
      name: 'Brand color 2',
    });

    fireEvent.input(enhancedBgInput, { target: { value: '#112233' } });
    fireEvent.input(enhancedTextInput, { target: { value: '#abcdef' } });

    expect(previewLogo.style.backgroundColor).toBe('rgb(17, 34, 51)');
    expect(previewLogo.style.fill).toBe('#abcdef');
  });

  it('falls back to the placeholder color when the input is cleared', () => {
    const bgInput = document.getElementById('organization_bg_color_hex');
    const previewLogo = document.getElementById('color-select-preview-logo');

    replaceTextInputWithColorPicker({
      input: bgInput,
      labelText: bgInput.dataset.labelText,
    });

    const clearButton = screen.getByRole('button', { name: 'Clear color' });
    fireEvent.click(clearButton);

    expect(previewLogo.style.backgroundColor).toBe('rgb(0, 0, 0)');
  });
});
