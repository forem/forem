/* eslint camelcase: "off" */

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
    this.checkRequirements = this.checkRequirements.bind(this);

    this.state = {
      checked_code_of_conduct: false,
      checked_terms_and_conditions: false,
      email_newsletter: true,
      email_digest_periodic: true,
      message: '',
      textShowing: null,
    };
  }

  componentDidMount() {
    updateOnboarding('emails, COC and T&C form');
  }

  onSubmit() {
    if (!this.checkRequirements()) return;
    const csrfToken = getContentOfToken('csrf-token');

    fetch('/onboarding_checkbox_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: this.state }),
      credentials: 'same-origin',
    }).then(response => {
      if (response.ok) {
        localStorage.setItem('shouldRedirectToOnboarding', false);
        const { next } = this.props;
        next();
      }
    });
  }

  checkRequirements() {
    const {
      checked_code_of_conduct,
      checked_terms_and_conditions,
    } = this.state;
    if (!checked_code_of_conduct) {
      this.setState({
        message: 'You must agree to our Code of Conduct before continuing!',
      });
      return false;
    }
    if (!checked_terms_and_conditions) {
      this.setState({
        message:
          'You must agree to our Terms and Conditions before continuing!',
      });
      return false;
    }
    return true;
  }

  handleChange(event) {
    const { name } = event.target;
    this.setState(currentState => ({
      [name]: !currentState[name],
    }));
  }

  handleShowText(event, id) {
    event.preventDefault();
    this.setState({ textShowing: document.getElementById(id).innerHTML });
  }

  backToSlide() {
    this.setState({ textShowing: null });
  }

  render() {
    const {
      message,
      checked_code_of_conduct,
      checked_terms_and_conditions,
      email_newsletter,
      email_digest_periodic,
      textShowing,
    } = this.state;
    const { prev } = this.props;
    if (textShowing) {
      return (
        <div className="onboarding-main">
          <div className="onboarding-content checkbox-slide">
            <button type="button" onClick={() => this.backToSlide()}>
              BACK
            </button>
            <div
              /* eslint-disable react/no-danger */
              dangerouslySetInnerHTML={{ __html: textShowing }}
              style={{ height: '360px', overflow: 'scroll' }}
              /* eslint-enable react/no-danger */
            />
          </div>
        </div>
      );
    }
    return (
      <div className="onboarding-main">
        <div className="onboarding-content checkbox-slide">
          <h2>Some things to check off!</h2>
          {message && <span className="warning-message">{message}</span>}
          <form>
            <label htmlFor="checked_code_of_conduct">
              <input
                type="checkbox"
                id="checked_code_of_conduct"
                name="checked_code_of_conduct"
                checked={checked_code_of_conduct}
                onChange={this.handleChange}
              />
              You agree to uphold our
              {' '}
              <a
                href="/code-of-conduct"
                data-no-instant
                onClick={e => this.handleShowText(e, 'coc')}
              >
                Code of Conduct
              </a>
            </label>
            <label htmlFor="checked_terms_and_conditions">
              <input
                type="checkbox"
                id="checked_terms_and_conditions"
                name="checked_terms_and_conditions"
                checked={checked_terms_and_conditions}
                onChange={this.handleChange}
              />
              You agree to our
              {' '}
              <a
                href="/terms"
                data-no-instant
                onClick={e => this.handleShowText(e, 'terms')}
              >
                Terms and Conditions
              </a>
            </label>
            <h3>Email Preferences</h3>
            <label htmlFor="email_newsletter">
              <input
                type="checkbox"
                id="email_newsletter"
                name="email_newsletter"
                checked={email_newsletter}
                onChange={this.handleChange}
              />
              Do you want to receive our weekly newsletter emails?
            </label>

            <label htmlFor="email_digest_periodic">
              <input
                type="checkbox"
                id="email_digest_periodic"
                name="email_digest_periodic"
                checked={email_digest_periodic}
                onChange={this.handleChange}
              />
              Do you want to receive a periodic digest with some of the top
              posts from your tags?
            </label>
          </form>
        </div>
        <Navigation prev={prev} next={this.onSubmit} />
      </div>
    );
  }
}

EmailTermsConditionsForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default EmailTermsConditionsForm;
