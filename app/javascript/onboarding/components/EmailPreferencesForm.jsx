import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getContentOfToken, updateOnboarding } from '../utilities';
import { Navigation } from './Navigation';
import { i18next } from '@utilities/locale';

/* eslint-disable camelcase */
export class EmailPreferencesForm extends Component {
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

    fetch('/onboarding_notifications_checkbox_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ notifications: this.state }),
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
                {i18next.t('onboarding.email.title')}
              </h1>
              <h2 id="subtitle" className="subtitle">
                {i18next.t('onboarding.email.subtitle')}
              </h2>
            </header>

            <form>
              <fieldset>
                <legend>{i18next.t('onboarding.email.legend')}</legend>
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
                      {i18next.t('onboarding.email.newsletter')}
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
                      {i18next.t('onboarding.email.periodic')}
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

/* eslint-enable camelcase */
