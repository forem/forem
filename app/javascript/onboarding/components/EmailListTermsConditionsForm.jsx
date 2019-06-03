import { h, Component } from 'preact';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

export default class extends Component {
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

  handleChange() {
    const { name, value } = event.target;
    this.setState(currentState => ({
      [name]: !currentState[name],
    }));
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

  render() {
    return (
      <div>
        <p>{this.state.message}</p>
        <form>
          <label htmlFor="checked_code_of_conduct">
            You agree to uphold our
            {' '}
            <a href="/code-of-conduct">Code of Conduct</a>
          </label>
          <input
            type="checkbox"
            name="checked_code_of_conduct"
            onChange={this.handleChange}
          />
          <label htmlFor="email_membership_newsletter">
            Do you want to receive our weekly newsletter emails?
          </label>
          <input
            type="checkbox"
            name="email_membership_newsletter"
            checked
            onChange={this.handleChange}
          />
          <label htmlFor="email_digest_periodic">
            Do you want to receive a periodic digest with some of the top posts
            from your tags?
          </label>
          <input
            type="checkbox"
            name="email_digest_periodic"
            checked
            onChange={this.handleChange}
          />
        </form>
        <Navigation prev={this.props.prev} next={this.onSubmit} />
      </div>
    );
  }
}
