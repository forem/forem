/* eslint camelcase: "off" */

import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

const setupFormTextField = ({
  labelText = '',
  entityName = '',
  placeholderText = '',
  onChangeCallback,
}) => {
  return (
    <label htmlFor={entityName}>
      {labelText}
      <input
        type="text"
        name={entityName}
        id={entityName}
        placeholder={placeholderText}
        onChange={onChangeCallback}
        maxLength="60"
      />
    </label>
  );
};

class PersonalInfoForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      location: '',
      employment_title: '',
      employer_name: '',
      last_onboarding_page: 'personal info form',
    };
  }

  componentDidMount() {
    const csrfToken = getContentOfToken('csrf-token');
    const { last_onboarding_page } = this.state;
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { last_onboarding_page } }),
      credentials: 'same-origin',
    });
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');

    const {
      last_onboarding_page,
      location,
      employer_name,
      employment_title,
    } = this.state;

    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: {
          last_onboarding_page,
          location,
          employer_name,
          employment_title,
        },
      }),
      credentials: 'same-origin',
    }).then(response => {
      if (response.ok) {
        const { next } = this.props;
        next();
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
    const { prev } = this.props;
    return (
      <div className="onboarding-main">
        <Navigation prev={prev} next={this.onSubmit} />
        <div className="onboarding-content">
          <header className="onboarding-content-header">
            <h1 className="title">About You</h1>
          </header>
          <form>
            {setupFormTextField({
              labelText: 'Where are you located?',
              entityName: 'location',
              placeholderText: 'e.g. New York, NY',
              onChangeCallback: this.handleChange,
            })}
            {setupFormTextField({
              labelText: 'What is your title?',
              entityName: 'employment_title',
              placeholderText: 'e.g. Software Engineer',
              onChangeCallback: this.handleChange,
            })}
            {setupFormTextField({
              labelText: 'Where do you work?',
              entityName: 'employer_name',
              placeholderText: 'e.g. Company name, self-employed, etc.',
              onChangeCallback: this.handleChange,
            })}
          </form>
        </div>
      </div>
    );
  }
}

setupFormTextField.propTypes = {
  labelText: PropTypes.string.isRequired,
  entityName: PropTypes.string.isRequired,
  placeholderText: PropTypes.string.isRequired,
  onChangeCallback: PropTypes.func.isRequired,
};

PersonalInfoForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default PersonalInfoForm;
