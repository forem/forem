import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

export const ErrorList = ({ errors }) => {
  return (
    <div
      data-testid="error-message"
      className="crayons-notice crayons-notice--danger mb-6"
    >
      <h3 className="fs-l mb-2 fw-bold">{i18next.t('errors.whoops')}</h3>
      <ul className="list-disc pl-6">
        {Object.keys(errors).map((key) => {
          return (
            // eslint-disable-next-line react/jsx-key
            <li>
              {key}
              {`: `}
              {errors[key]}
            </li>
          );
        })}
      </ul>
    </div>
  );
};

ErrorList.propTypes = {
  errors: PropTypes.objectOf(PropTypes.string).isRequired,
};

ErrorList.displayName = 'ErrorList';
