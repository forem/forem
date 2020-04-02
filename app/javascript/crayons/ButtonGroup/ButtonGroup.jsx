import { h } from 'preact';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

export const ButtonGroup = ({ children }) => (
  <div className="crayons-btn-group">{children}</div>
);

ButtonGroup.displayName = 'ButtonGroup';

ButtonGroup.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};
