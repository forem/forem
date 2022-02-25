import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { useState, useLayoutEffect } from 'preact/hooks';
import { HexColorPicker, HexColorInput } from 'react-colorful';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { ButtonNew as Button } from '@crayons';

export const ColorPicker = ({
  id,
  buttonLabelText,
  defaultValue,
  inputProps,
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
      <div className="c-color-picker relative">
        <Button
          id={buttonId}
          className="c-btn c-color-picker__swatch absolute"
          style={{ backgroundColor: color }}
          aria-label={buttonLabelText}
        />
        <HexColorInput
          id={id}
          className={classNames(
            'c-color-picker__input crayons-textfield',
            inputProps?.class,
          )}
          color={color}
          onChange={setColor}
          prefixed
          {...inputProps}
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
  buttonLabelText: PropTypes.string.isRequired,
  defaultValue: PropTypes.string,
  inputProps: PropTypes.object,
};
