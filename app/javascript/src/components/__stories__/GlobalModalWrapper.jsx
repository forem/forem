import { h } from 'preact';
import { defaultChildrenPropTypes } from '../../../common-prop-types';

const GlobalModalWrapper = ({ children }) => (
  <div className="global-modal">
    <div className="modal-body">{children}</div>
  </div>
);

GlobalModalWrapper.propTypes = {
  // Diabling linting below because of https://github.com/yannickcr/eslint-plugin-react/issues/1389
  // eslint-disable-next-line react/no-typos
  children: defaultChildrenPropTypes.isRequired,
};

export default GlobalModalWrapper;
