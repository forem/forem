import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export class Navigation extends Component {
  /**
   * A function to render the progress stepper within the `Navigation` component.
   * By default, it does not show the stepper for the first slide (the `IntroSlide` component).
   * It builds a list of `<span>` elements corresponding to the slides, and adds an "active"
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

      stepsList.push(<span class={`dot ${active ? 'active' : ''}`} />);
    }
    return (
      <div data-testid="stepper" class="stepper">
        {stepsList}
      </div>
    );
  }

  /**
   * A function to render the text for the "next-button" within the `Navigation` component.
   * By default, it renders "Continue" for every slide.
   * If the slide can be skipped, it renders "Skip for now".
   * On the final slide, it renders "Finish".
   *
   * @returns {String} The HTML markup for the stepper.
   */
  buttonText() {
    const { canSkip, currentSlideIndex, slidesCount } = this.props;
    if (slidesCount - 1 === currentSlideIndex) {
      return 'Finish';
    }
    if (canSkip) {
      return 'Skip for now';
    }

    return 'Continue';
  }

  render() {
    const { next, prev, hideNext, hidePrev, disabled, canSkip, className } =
      this.props;
    return (
      <nav
        class={`onboarding-navigation${
          className && className.length > 0 ? ` ${className}` : ''
        }`}
      >
        <div
          class={`navigation-content${
            className && className.length > 0 ? ` ${className}` : ''
          }`}
        >
          {!hidePrev && (
            <div class="back-button-container">
              <button
                onClick={prev}
                data-testid="back-button"
                class="back-button"
                type="button"
                aria-label="Back to previous onboarding step"
              >
                <svg
                  width="24"
                  height="24"
                  fill="none"
                  class="crayons-icon"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M7.828 11H20v2H7.828l5.364 5.364-1.414 1.414L4 12l7.778-7.778 1.414 1.414L7.828 11z" />
                </svg>
              </button>
            </div>
          )}

          {this.createStepper()}

          {!hideNext && (
            <button
              disabled={disabled}
              onClick={next}
              class={`next-button${canSkip ? ' skip-for-now' : ''}`}
              type="button"
            >
              {this.buttonText()}
            </button>
          )}
        </div>
      </nav>
    );
  }
}

Navigation.propTypes = {
  disabled: PropTypes.bool,
  canSkip: PropTypes.bool,
  class: PropTypes.string,
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  hideNext: PropTypes.bool,
  hidePrev: PropTypes.bool,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired,
};

Navigation.defaultProps = {
  disabled: false,
  canSkip: false,
  hideNext: false,
  hidePrev: false,
  class: '',
};
