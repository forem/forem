import { h } from 'preact';
import PropTypes from 'prop-types';

export const ErrorList = ({ errors }) => {
  return (
    <div
      data-testid="error-message"
      className="crayons-notice crayons-notice--danger mb-6"
    >
      <h3 className="fs-l mb-2 fw-bold">Whoops, something went wrong:</h3>
      <ul className="list-disc pl-6">
        {Object.keys(errors).map((key) => {
          return (
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
