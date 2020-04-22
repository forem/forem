import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class Navigation extends Component {
  /**
   * A function to render the progress stepper within the `Navigation` component.
   * By default, it does not show the stepper for the first slide (the `IntroSlide` component).
   * It builds a list of `<span>` elements correseponding to the slides, and adds an "active"
   * class to any slide that has already been seen or is currently being seen.
   *
   * @returns {String} The HTML markup for the stepper.
   */
  createStepper() {
    const { currentSlideIndex, slidesCount } = this.props;
    if (currentSlideIndex === 0) {
      return '';
    }

    const stepsList = [];

    // We do not show the stepper on the IntroSlide so we start with `i = 1`.
    for (let i = 1; i < slidesCount; i += 1) {
      const active = i <= currentSlideIndex;

      stepsList.push(<span className={`dot ${active ? 'active' : ''}`} />);
    }
    return <div className="stepper">{stepsList}</div>;
  }

  render() {
    const { next, prev, hideNext, hidePrev, disabled, className } = this.props;
    return (
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
              <svg
                width="16"
                height="16"
                fill="none"
                className="crayons-icon"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M3.828 7H16v2H3.828l5.364 5.364-1.414 1.414L0 8 7.778.222l1.414 1.414L3.828 7z" />
              </svg>
            </button>
          )}

          {this.createStepper()}

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
  }
}

Navigation.propTypes = {
  disabled: PropTypes.bool,
  className: PropTypes.string,
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  hideNext: PropTypes.bool,
  hidePrev: PropTypes.bool,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired,
};

Navigation.defaultProps = {
  disabled: false,
  hideNext: false,
  hidePrev: false,
  className: '',
};

export default Navigation;
