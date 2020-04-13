import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken, updateOnboarding } from '../utilities';

/* eslint-disable camelcase */
class EmailTermsConditionsForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      email_newsletter: true,
      email_digest_periodic: true,
    };
  }

  componentDidMount() {
    updateOnboarding('v2: email preferences');
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
    const { prev } = this.props;
    return (
      <div className="onboarding-main">
        <Navigation prev={prev} next={this.onSubmit} />
        <div className="onboarding-content terms-and-conditions-wrapper">
          <header className="onboarding-content-header">
            <h1 className="title">Getting started</h1>
            <h2 className="subtitle">Let&apos;s review a few things first</h2>
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
                    I want to receive a periodic digest with some of the top
                    posts from your tags.
                  </label>
                </li>
              </ul>
            </fieldset>
          </form>
        </div>
      </div>
    );
  }
}

EmailTermsConditionsForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default EmailTermsConditionsForm;

/* eslint-enable camelcase */
