import { h } from 'preact';
import PropTypes from 'prop-types';
import { locale } from '../../utilities/locale';

export const ErrorList = ({ errors }) => {
  return (
    <div
      data-testid="error-message"
      className="crayons-notice crayons-notice--danger mb-6"
    >
      <h3 className="fs-l mb-2 fw-bold">
        {locale('views.editor.errors.something_wrong')}
      </h3>
      <ul className="list-disc pl-6">
        {Object.keys(errors).map((key) => {
          return (
            <li key={key}>
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
  errors: PropTypes.object.isRequired,
};

ErrorList.displayName = 'ErrorList';
