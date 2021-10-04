import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

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
      {i18next.t('listings.form.connect.subtitle')}
      <p className="crayons-field__description">
        {i18next.t('listings.form.connect.desc')}
      </p>
    </label>
  </div>
);

ContactViaConnect.propTypes = {
  onChange: PropTypes.func.isRequired,
  checked: PropTypes.bool.isRequired,
};
