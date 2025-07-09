import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Navigation } from './Navigation';

/* eslint-disable camelcase */
export class CustomCta extends Component {
  // A simple handler to proceed to the next slide.
  onNext = () => {
    const { next } = this.props;
    // You can add any logic here that needs to happen before moving to the next slide.
    localStorage.setItem('shouldRedirectToOnboarding', false);
    next();
  };

  render() {
    const { prev, slidesCount, currentSlideIndex } = this.props;
    return (
      <div
        data-testid="onboarding-follow-suggestions-form"
        className="onboarding-main crayons-modal crayons-modal--large"
      >
        <div
          className="crayons-modal__box"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <div className="onboarding-content">
            <h2 id="title" class="crayons-modal__title">Customize Your Feed</h2>
            <p id="subtitle" class="crayons-modal__description">
              Follow tags and organizations to personalize your experience and discover relevant content.
            </p>
            <div class="onboarding-actions-list">
              <a href="/t/challenge" target="_blank" rel="noopener noreferrer" class="crayons-btn crayons-btn--secondary crayons-btn--l" style={{ marginBottom: '1rem', display: 'block' }}>
                Follow Dev Challenges
              </a>
              <a href="/t/education" target="_blank" rel="noopener noreferrer" class="crayons-btn crayons-btn--secondary crayons-btn--l" style={{ marginBottom: '1rem', display: 'block' }}>
                Follow Dev Education Tracks
              </a>
              <a href="/google-ai" target="_blank" rel="noopener noreferrer" class="crayons-btn crayons-btn--secondary crayons-btn--l" style={{ display: 'block' }}>
                Follow the Google AI Org
              </a>
            </div>
          </div>
          <Navigation
            prev={prev}
            next={this.onNext} // Use the simplified 'onNext' handler
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
            nextText="Finish" // Optional: Change button text
          />
        </div>
      </div>
    );
  }
}

CustomCta.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired, // Corrected to func
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired, // Corrected to number
};

/* eslint-enable camelcase */