import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { useState, useLayoutEffect } from 'preact/hooks';
import { HexColorPicker, HexColorInput } from 'react-colorful';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { ButtonNew as Button } from '@crayons';

const convertThreeCharHexToSix = (hex) => {
  const r = hex.charAt(1);
  const g = hex.charAt(2);
  const b = hex.charAt(3);

  return `#${r}${r}${g}${g}${b}${b}`;
};

export const ColorPicker = ({
  id,
  buttonLabelText,
  defaultValue,
  inputProps,
  onChange,
  onBlur,
}) => {
  const [color, setColor] = useState(defaultValue || '');

  const buttonId = `color-popover-btn-${id}`;
  const popoverId = `color-popover-${id}`;

  useLayoutEffect(() => {
    initializeDropdown({
      triggerElementId: buttonId,
      dropdownContentId: popoverId,
    });
  }, [buttonId, popoverId]);

  // Hex codes may validly be represented by three characters, where r, g, b are all repeated,
  // e.g. #0D6 === #00DD66. To make sure that all color codes can be handled consistently through our app,
  // we convert any shorthand hex codes to their full 6 char representation.
  const handleBlur = () => {
    // Color always includes a leading '#', hence a length of 4
    if (color.length === 4) {
      const fullHexCode = convertThreeCharHexToSix(color);
      setColor(fullHexCode);
      onChange?.(fullHexCode);
    }
  };

  const handleClear = () => {
    setColor('');
    onChange?.('');
  };

  const hasColor = color && color.length > 0;

  // Separate the name from inputProps so the HexColorInput doesn't submit directly.
  // Instead, a hidden input with the name is used for form submission.
  const { name: inputName, ...displayInputProps } = inputProps || {};

  return (
    <Fragment>
      <div className="c-color-picker relative w-100">
        {/* Hidden input carries the actual form value */}
        <input type="hidden" name={inputName} value={hasColor ? color : ''} />
        <Button
          id={buttonId}
          className="c-btn c-color-picker__swatch absolute"
          style={{
            backgroundColor: hasColor ? color : 'transparent',
            border: hasColor ? 'none' : '1px dashed var(--base-60, #ccc)',
          }}
          aria-label={buttonLabelText}
        />
        <HexColorInput
          {...displayInputProps}
          id={id}
          className={classNames(
            'c-color-picker__input crayons-textfield',
            displayInputProps?.class,
          )}
          color={hasColor ? color : ''}
          onChange={(newColor) => {
            onChange?.(newColor);
            setColor(newColor);
          }}
          onBlur={(e) => {
            onBlur?.(e);
            handleBlur();
          }}
          prefixed
        />
        {hasColor && (
          <button
            type="button"
            className="c-color-picker__clear absolute"
            onClick={handleClear}
            aria-label="Clear color"
            title="Clear color"
          >
            ✕
          </button>
        )}
        <div
          id={popoverId}
          className="c-color-picker__popover crayons-dropdown absolute p-0"
        >
          <HexColorPicker
            color={hasColor ? color : '#000000'}
            onChange={(newColor) => {
              onChange?.(newColor);
              setColor(newColor);
            }}
          />
        </div>
      </div>
    </Fragment>
  );
};

ColorPicker.propTypes = {
  id: PropTypes.string.isRequired,
  buttonLabelText: PropTypes.string.isRequired,
  defaultValue: PropTypes.string,
  inputProps: PropTypes.object,
};
