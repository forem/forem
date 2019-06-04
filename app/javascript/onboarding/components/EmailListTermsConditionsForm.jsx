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
      checked_code_of_conduct: false,
      email_membership_newsletter: true,
      email_digest_periodic: true,
      message: '',
    };
  }

  checkRequirements() {
    if (!this.state.checked_code_of_conduct) {
      this.setState({
        message: 'You must agree to our Code of Conduct before continuing!',
      });
      return;
    }
    return true;
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
        this.props.next();
      }
    });
  }

  handleChange() {
    const { name } = event.target;
    this.setState(currentState => ({
      [name]: !currentState[name],
    }));
  }

  render() {
    return (
      <div>
        <p>{this.state.message}</p>
        <form>
          <label htmlFor="checked_code_of_conduct">
            You agree to uphold our
            {' '}
            <a href="/code-of-conduct">Code of Conduct</a>
            <input
              type="checkbox"
              name="checked_code_of_conduct"
              onChange={this.handleChange}
            />
          </label>
          <label htmlFor="email_membership_newsletter">
            Do you want to receive our weekly newsletter emails?
            <input
              type="checkbox"
              name="email_membership_newsletter"
              checked
              onChange={this.handleChange}
            />
          </label>

          <label htmlFor="email_digest_periodic">
            Do you want to receive a periodic digest with some of the top posts
            from your tags?
            <input
              type="checkbox"
              name="email_membership_newsletter"
              checked
              onChange={this.handleChange}
            />
          </label>
        </form>
        <Navigation prev={this.props.prev} next={this.onSubmit} />
      </div>
    );
  }
}

EmailTermsConditionsForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default EmailTermsConditionsForm;
