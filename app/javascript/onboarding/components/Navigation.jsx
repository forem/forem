import { h } from 'preact';
import PropTypes from 'prop-types';

const Navigation = ({ next, prev, hideNext, hidePrev }) => (
  <nav className="onboarding-navigation">
    <div className="navigation-content">
      {!hidePrev && (
        <button onClick={prev} className="back-button" type="button">
          Back
        </button>
      )}
      {!hideNext && (
        <button onClick={next} className="next-button" type="button">
          Continue
        </button>
      )}
    </div>
  </nav>
);

Navigation.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  hideNext: PropTypes.bool,
  hidePrev: PropTypes.bool,
};

Navigation.defaultProps = {
  hideNext: false,
  hidePrev: false,
};

export default Navigation;
