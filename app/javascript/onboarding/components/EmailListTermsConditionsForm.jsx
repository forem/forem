import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class EmailTermsConditionsForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.checkRequirements = this.checkRequirements.bind(this);

    this.state = {
      checkedCodeOfConduct: false,
      checkedTermsAndConditions: false,
      emailMembershipNewsletter: true,
      emailDigestPeriodic: true,
      message: '',
      textShowing: null,
    };
  }

  componentDidMount() {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: { last_onboarding_page: 'emails, COC and T&C form' },
      }),
      credentials: 'same-origin',
    });
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
    const { checkedCodeOfConduct, checkedTermsAndConditions } = this.state;
    if (!checkedCodeOfConduct) {
      this.setState({
        message: 'You must agree to our Code of Conduct before continuing!',
      });
      return false;
    }
    if (!checkedTermsAndConditions) {
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
      checkedCodeOfConduct,
      checkedTermsAndConditions,
      emailMembershipNewsletter,
      emailDigestPeriodic,
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
                name="checkedCodeOfConduct"
                checked={checkedCodeOfConduct}
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
                name="checkedTermsAndConditions"
                checked={checkedTermsAndConditions}
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
            <label htmlFor="email_membership_newsletter">
              <input
                type="checkbox"
                id="email_membership_newsletter"
                name="emailMembershipNewsletter"
                checked={emailMembershipNewsletter}
                onChange={this.handleChange}
              />
              Do you want to receive our weekly newsletter emails?
            </label>

            <label htmlFor="email_digest_periodic">
              <input
                type="checkbox"
                id="email_digest_periodic"
                name="emailDigestPeriodic"
                checked={emailDigestPeriodic}
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
