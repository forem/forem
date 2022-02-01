import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { useState, useLayoutEffect } from 'preact/hooks';
import { HexColorPicker, HexColorInput } from 'react-colorful';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { ButtonNew as Button } from '@crayons';

export const ColorPicker = ({
  id,
  labelText,
  defaultValue,
  showLabel = true,
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

  return (
    <Fragment>
      {showLabel && (
        <label
          for={id}
          className={`crayons-field__label ${
            showLabel ? '' : 'screen-reader-only'
          }`}
        >
          {labelText}
        </label>
      )}
      <div className="c-color-picker relative">
        <Button
          id={buttonId}
          className="c-btn c-color-picker__swatch absolute"
          style={{ backgroundColor: color }}
          aria-label={labelText}
        />
        <HexColorInput
          id={id}
          className="c-color-picker__input crayons-textfield "
          color={color}
          onChange={setColor}
          prefixed
        />
        <div
          id={popoverId}
          className="c-color-picker__popover crayons-dropdown absolute p-0"
        >
          <HexColorPicker color={color} onChange={setColor} />
        </div>
      </div>
    </Fragment>
  );
};

ColorPicker.propTypes = {
  id: PropTypes.string.isRequired,
  labelText: PropTypes.string.isRequired,
  defaultValue: PropTypes.string,
  showLabel: PropTypes.bool,
};
