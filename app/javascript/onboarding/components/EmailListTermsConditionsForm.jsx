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
        message: 'You must agree to our Code of Conduct before continuing.',
      });
      return false;
    }
    if (!checked_terms_and_conditions) {
      this.setState({
        message:
          'You must agree to our Terms and Conditions before continuing.',
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
              Back
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
        <Navigation prev={prev} next={this.onSubmit} />
        <div className="onboarding-content checkbox-slide">
          <header className="onboarding-content-header">
            <h1 className="title">Getting started</h1>
            <h2 className="subtitle">Let&apos;s review a few things first</h2>
          </header>

          {message && (
            <span className="crayons-notice crayons-notice--danger">
              {message}
            </span>
          )}

          <form>
            <fieldset>
              <legend>Some things to check off</legend>
              <ul>
                <li className="checkbox-item">
                  <label htmlFor="checked_code_of_conduct">
                    <input
                      type="checkbox"
                      id="checked_code_of_conduct"
                      name="checked_code_of_conduct"
                      checked={checked_code_of_conduct}
                      onChange={this.handleChange}
                    />
                    I agree to uphold the
                    {' '}
                    <a
                      href="/code-of-conduct"
                      data-no-instant
                      onClick={e => this.handleShowText(e, 'coc')}
                    >
                      Code of Conduct
                    </a>
                  </label>
                </li>

                <li className="checkbox-item">
                  <label htmlFor="checked_terms_and_conditions">
                    <input
                      type="checkbox"
                      id="checked_terms_and_conditions"
                      name="checked_terms_and_conditions"
                      checked={checked_terms_and_conditions}
                      onChange={this.handleChange}
                    />
                    I agree to our
                    {' '}
                    <a
                      href="/terms"
                      data-no-instant
                      onClick={e => this.handleShowText(e, 'terms')}
                    >
                      Terms and Conditions
                    </a>
                  </label>
                </li>
              </ul>
            </fieldset>

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
