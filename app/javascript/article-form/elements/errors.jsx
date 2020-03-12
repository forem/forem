import { h } from 'preact';
import PropTypes from 'prop-types';

const Errors = ({ errorsList }) => (
  <div className="articleform__errors">
    <h2>
      <span role="img" aria-label="face screaming in fear">
        😱
      </span>
      &nbsp; Heads up:
    </h2>
    <ul>
      {Object.keys(errorsList).map(key => {
        return (
          <li>
            {key}
            : &nbsp;
            {errorsList[key]}
          </li>
        );
      })}
    </ul>
  </div>
);

Errors.propTypes = {
  errorsList: PropTypes.objectOf(PropTypes.string).isRequired,
};

export default Errors;
