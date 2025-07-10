import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Navigation } from './Navigation';
import { getContentOfToken } from '../utilities';

/* eslint-disable camelcase */
export class CustomCta extends Component {
  // State and handlers remain the same
  state = {
    follow_challenges: true,
    follow_education_tracks: true,
    follow_featured_accounts: true,
  };

  handleCheckboxChange = (e) => {
    const { name, checked } = e.target;
    this.setState({ [name]: checked });
  };

  handleComplete = async () => {
    const csrfToken = getContentOfToken('csrf-token');
    const { next } = this.props;
    const payload = this.state;

    try {
      await fetch('/onboarding/custom_actions', {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        credentials: 'same-origin',
      });
    } catch (error) {
      console.error('Error submitting custom actions:', error);
    }

    next();
  };

  render() {
    const { prev, slidesCount, currentSlideIndex } = this.props;
    const { follow_challenges, follow_education_tracks, follow_featured_accounts } = this.state;

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
            <header className="onboarding-content-header">
              <h1 id="title" className="title">Special Initiatives</h1>
              <h2 id="subtitle" className="subtitle" style='line-height: 1.4em;margin-top: 0.5em;'>
                DEV offers exclusive events that help you grow as a developer and certify your skills. Follow these special tags to make sure you never miss an update.
              </h2>
            </header>
            
            <div className="onboarding-actions-list">
              {/* Item 1 with Sub-header */}
              <label className={`onboarding-actions-list__item ${follow_challenges ? '--selected' : ''}`}>
                <input
                  className="onboarding-actions-list__checkbox"
                  type="checkbox"
                  name="follow_challenges"
                  checked={follow_challenges}
                  onChange={this.handleCheckboxChange}
                />
                <span className="onboarding-actions-list__label-text">
                  <span className="block fw-medium">Follow DEV Challenges</span>
                  <span className="block fs-s color-base-70 mt-0">
                    We offer special coding challenges, hackathons and writing challenges to help you sharpen your skills and win prizes.
                  </span>
                </span>
              </label>

              {/* Item 2 with Sub-header */}
              <label className={`onboarding-actions-list__item ${follow_education_tracks ? '--selected' : ''}`}>
                <input
                  className="onboarding-actions-list__checkbox"
                  type="checkbox"
                  name="follow_education_tracks"
                  checked={follow_education_tracks}
                  onChange={this.handleCheckboxChange}
                />
                <span className="onboarding-actions-list__label-text">
                  <span className="block fw-medium">Follow DEV Education Tracks</span>
                  <span className="block fs-s color-base-70 mt-0">
                    Get curated educational content and tutorials on a variety of development topics.
                  </span>
                </span>
              </label>

              {/* Item 3 with Sub-header */}
              <label className={`onboarding-actions-list__item ${follow_featured_accounts ? '--selected' : ''}`}>
                <input
                  className="onboarding-actions-list__checkbox"
                  type="checkbox"
                  name="follow_featured_accounts"
                  checked={follow_featured_accounts}
                  onChange={this.handleCheckboxChange}
                />
                <span className="onboarding-actions-list__label-text">
                  <span className="block fw-medium">Follow the Google AI Org Account</span>
                  <span className="block fs-s color-base-70 mt-0">
                    We have partnered with Google AI on custom education tracks for upgrading your skills in AI and machine learning.
                  </span>
                </span>
              </label>
            </div>
          </div>
          <Navigation
            prev={prev}
            next={this.handleComplete}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
          />
        </div>
      </div>
    );
  }
}

CustomCta.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired,
};

/* eslint-enable camelcase */