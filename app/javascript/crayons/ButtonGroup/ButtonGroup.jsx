import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';

/**
 * Used to group related buttons together
 *
 * @param {string} labelText Used to form the aria-label providing to assistive technologies to describe the control
 * @param {HTMLElement[]} children The buttons rendered inside the group
 */
export const ButtonGroup = ({ children, labelText }) => (
  <div role="group" aria-label={labelText} className="crayons-btn-group">
    {children}
  </div>
);

ButtonGroup.displayName = 'ButtonGroup';

ButtonGroup.propTypes = {
  children: defaultChildrenPropTypes,
  labelText: PropTypes.string.isRequired,
};
