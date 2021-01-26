import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { getContentOfToken, updateOnboarding } from '../utilities';
import Navigation from './Navigation';

/* eslint-disable camelcase */
class EmailPreferencesForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      email_newsletter: false,
      email_digest_periodic: false,
    };
  }

  componentDidMount() {
    updateOnboarding('v2: email preferences form');
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');

    fetch('/onboarding_checkbox_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: this.state }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        localStorage.setItem('shouldRedirectToOnboarding', false);
        const { next } = this.props;
        next();
      }
    });
  }

  handleChange(event) {
    const { name } = event.target;
    this.setState((currentState) => ({
      [name]: !currentState[name],
    }));
  }

  render() {
    const { email_newsletter, email_digest_periodic } = this.state;
    const { prev, slidesCount, currentSlideIndex } = this.props;
    return (
      <div
        data-testid="onboarding-email-preferences-form"
        className="onboarding-main crayons-modal"
      >
        <div
          className="crayons-modal__box"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <Navigation
            prev={prev}
            next={this.onSubmit}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
          />
          <div className="onboarding-content terms-and-conditions-wrapper">
            <header className="onboarding-content-header">
              <h1 id="title" className="title">
                Almost there!
              </h1>
              <h2 id="subtitle" className="subtitle">
                Review your email preferences before we continue.
              </h2>
            </header>

            <form>
              <fieldset>
                <legend>Email preferences</legend>
                <ul>
                  <li className="checkbox-item">
                    <label htmlFor="email_newsletter">
                      <input
                        type="checkbox"
                        id="email_newsletter"
                        name="email_newsletter"
                        checked={email_newsletter}
                        onChange={this.handleChange}
                      />
                      I want to receive weekly newsletter emails.
                    </label>
                  </li>
                  <li className="checkbox-item">
                    <label htmlFor="email_digest_periodic">
                      <input
                        type="checkbox"
                        id="email_digest_periodic"
                        name="email_digest_periodic"
                        checked={email_digest_periodic}
                        onChange={this.handleChange}
                      />
                      I want to receive a periodic digest of top posts from my
                      tags.
                    </label>
                  </li>
                </ul>
              </fieldset>
            </form>
          </div>
        </div>
      </div>
    );
  }
}

EmailPreferencesForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
};

export default EmailPreferencesForm;

/* eslint-enable camelcase */
