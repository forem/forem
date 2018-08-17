import { h } from 'preact';
import PropTypes from 'prop-types';

const Errors = ({ errorsList }) => (
  <div className='articleform__errors'>
    <h2>😱 Heads up:</h2>
    <ul>{Object.keys(errorsList).map((key) => {
      return <li>{key}: {errorsList[key]}</li>
    })}</ul>
  </div>
);

Errors.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default Errors;
