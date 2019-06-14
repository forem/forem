import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class PersonalInfoForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      summary: '', // eslint-disable-line no-unused-state
      location: '', // eslint-disable-line no-unused-state
      employment_title: '', // eslint-disable-line no-unused-state
      employer_name: '', // eslint-disable-line no-unused-state
    };
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');

    fetch('/onboarding_update', {
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

  handleChange(e) {
    const { name, value } = e.target;

    this.setState({
      [name]: value,
    });
  }

  render() {
    return (
      <div className="about">
        <h2>About You!</h2>
        <form>
          <label htmlFor="summary">
            Tell the community about yourself! Write a quick bio about what you
            do, what you're interested in, or anything else!
            <textarea
              name="summary"
              onChange={this.handleChange}
              maxLength="120"
            />
          </label>
          <label htmlFor="location">
            Where are you located?
            <input
              type="text"
              name="location"
              onChange={this.handleChange}
              maxLength="60"
            />
          </label>
          <label htmlFor="employment_title">
            What is your title?
            <input
              type="text"
              name="employment_title"
              onChange={this.handleChange}
              maxLength="60"
            />
          </label>

          <label htmlFor="employer_name">
            Where do you work?
            <input
              type="text"
              name="employer_name"
              onChange={this.handleChange}
              maxLength="60"
            />
          </label>
        </form>
        <Navigation prev={this.props.prev} next={this.onSubmit} />
      </div>
    );
  }
}

PersonalInfoForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default PersonalInfoForm;
