import { h } from 'preact';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

export const Fieldset = ({ children }) => (
  <fieldset style={{ border: 'none' }}>{children}</fieldset>
);

Fieldset.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};
