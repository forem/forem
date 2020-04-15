import { h } from 'preact';
import PropTypes from 'prop-types';

const Navigation = ({
  next,
  prev,
  hideNext,
  hidePrev,
  disabled,
  className,
}) => (
  <nav
    className={`onboarding-navigation${
      className && className.length > 0 ? ` ${className}` : ''
    }`}
  >
    <div
      className={`navigation-content${
        className && className.length > 0 ? ` ${className}` : ''
      }`}
    >
      {!hidePrev && (
        <button onClick={prev} className="back-button" type="button">
          Back
        </button>
      )}
      {!hideNext && (
        <button
          disabled={disabled}
          onClick={next}
          className="next-button"
          type="button"
        >
          Continue
        </button>
      )}
    </div>
  </nav>
);

Navigation.propTypes = {
  disabled: PropTypes.bool,
  className: PropTypes.string,
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  hideNext: PropTypes.bool,
  hidePrev: PropTypes.bool,
};

Navigation.defaultProps = {
  disabled: false,
  hideNext: false,
  hidePrev: false,
  className: '',
};

export default Navigation;
