import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

const setupFormTextField = ({ labelText = '', entityName = '', onChangeCallback }) => {
  return (
    <label htmlFor={entityName}>
      {labelText}
      <input
        type="text"
        name={entityName}
        id={entityName}
        onChange={onChangeCallback}
        maxLength="60"
      />
    </label>
  )
}

class PersonalInfoForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      location: '',
      employmentTitle: '',
      employerName: '',
      lastOnboardingPage: 'personal info form',
    };
  }

  componentDidMount() {
    const csrfToken = getContentOfToken('csrf-token');
    const { lastOnboardingPage } = this.state;
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { lastOnboardingPage } }),
      credentials: 'same-origin',
    });
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');

    const {
      lastOnboardingPage,
      location,
      employerName,
      employmentTitle,
    } = this.state;

    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: {
          lastOnboardingPage,
          location,
          employerName,
          employmentTitle,
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
        <div className="onboarding-content about">
          <h2>About You!</h2>
          <form>
            {
              setupFormTextField({
                labelText: 'Where are you located?',
                entityName: 'location',
                onChangeCallback: this.handleChange
              })
            }
            {
              setupFormTextField({
                labelText: 'What is your title?',
                entityName: 'employment_title',
                onChangeCallback: this.handleChange
              })
            }
            {
              setupFormTextField({
                labelText: 'Where do you work?',
                entityName: 'employer_name',
                onChangeCallback: this.handleChange
              })
            }
          </form>
        </div>
        <Navigation prev={prev} next={this.onSubmit} />
      </div>
    );
  }
}

PersonalInfoForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default PersonalInfoForm;
