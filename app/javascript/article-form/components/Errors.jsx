import { h } from 'preact';
import PropTypes from 'prop-types';

export const Errors = ({ errorsList }) => {
  return (
    <div className="crayons-notice crayons-notice--danger mb-6">
      <h3 className="fs-l mb-2 fw-bold">Whoops, something went wrong:</h3>
      <ul className="list-disc pl-6">
        {Object.keys(errorsList).map((key) => {
          return (
            <li>
              {key}
              {`: `}
              {errorsList[key]}
            </li>
          );
        })}
      </ul>
    </div>
  );
};

Errors.propTypes = {
  errorsList: PropTypes.objectOf(PropTypes.string).isRequired,
};

Errors.displayName = 'Errors';
