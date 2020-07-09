import { h } from 'preact';
import { defaultChildrenPropTypes } from '../../common-prop-types';

export const ButtonGroup = ({ children }) => (
  <div role="presentation" className="crayons-btn-group">
    {children}
  </div>
);

ButtonGroup.displayName = 'ButtonGroup';

ButtonGroup.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};
