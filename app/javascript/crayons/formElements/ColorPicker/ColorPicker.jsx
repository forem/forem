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
  // Ternary has been used here to guard against an empty string being passed as default value
  const [color, setColor] = useState(defaultValue ? defaultValue : '#000');

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

  return (
    <Fragment>
      <div className="c-color-picker relative w-100">
        <Button
          id={buttonId}
          className="c-btn c-color-picker__swatch absolute"
          style={{ backgroundColor: color }}
          aria-label={buttonLabelText}
        />
        <HexColorInput
          {...inputProps}
          id={id}
          className={classNames(
            'c-color-picker__input crayons-textfield',
            inputProps?.class,
          )}
          color={color}
          onChange={(color) => {
            onChange?.(color);
            setColor(color);
          }}
          onBlur={(e) => {
            onBlur?.(e);
            handleBlur();
          }}
          prefixed
        />
        <div
          id={popoverId}
          className="c-color-picker__popover crayons-dropdown absolute p-0"
        >
          <HexColorPicker
            color={color}
            onChange={(color) => {
              onChange?.(color);
              setColor(color);
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
