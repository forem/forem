import { h } from 'preact';
import PropTypes from 'prop-types';

export const ContactViaConnect = ({ onChange, checked }) => (
  <div className="crayons-field crayons-field--checkbox">
    <input
      type="checkbox"
      className="crayons-checkbox"
      id="contact_via_connect"
      name="listing[contact_via_connect]"
      onInput={onChange}
      checked={checked}
    />

    <label
      id="label-contact-via-connect"
      className="crayons-field__label"
      htmlFor="contact_via_connect"
    >
      Connect messaging
      <p className="crayons-field__description">
        Allow Users to message me via Connect.
      </p>
    </label>
  </div>
);

ContactViaConnect.propTypes = {
  onChange: PropTypes.func.isRequired,
  checked: PropTypes.bool.isRequired,
};
