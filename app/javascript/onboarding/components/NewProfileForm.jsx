import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { userData, getContentOfToken, updateOnboarding } from '../utilities';
import Navigation from './Navigation';

/* eslint-disable camelcase */
class NewProfileForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.user = userData();
    this.state = {
      groups: [],
      formValues: {},
      canSkip: true,
      last_onboarding_page: 'v2: new personal info form',
    };
  }

  componentDidMount() {
    fetch('/profile_field_groups?onboarding=true')
      .then((response) => response.json())
      .then((data) => {
        this.setState({ groups: data.profile_field_groups });
      });

    updateOnboarding('v2: new personal info form');
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');
    const { formValues, last_onboarding_page } = this.state;
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { last_onboarding_page }, profile: {...formValues} }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        const { next } = this.props;
        next();
      }
    });
  }

  handleChange(e) {
    const { formValues } = { ...this.state };
    const currentFormState = formValues;
    const { name, value } = e.target;

    currentFormState[name] = value

    // Once we've derived the new form values, check if the form is empty
    // and use that value to set the `canSkip` property on the state.
    const formIsEmpty =
      Object.values(currentFormState).filter((v) => v.length > 0).length === 0;

    this.setState({ formValues: currentFormState, canSkip: formIsEmpty });
  }

  checkboxField(field) {
    return (
      <div class="crayons-field crayons-field--checkbox">
        <input class="crayons-checkbox" type="checkbox" name={field.attribute_name} id={field.attribute_name} onChange={this.handleChange}></input>
        <label class="crayons-field__label" for="profile[field.attribute_name]">
          {field.label}
        </label>
        {field.description && <p class="crayons-field__description">{field.description}</p>}
      </div>
    )
  }

  textField(field) {
    return (
      <div>
        <label class="crayons-field__label" for="profile[field.attribute_name]">
          {field.label}
        </label>
        <input class="crayons-textfield" placeholder_text={field["placeholder_text"]} name={field.attribute_name} id={field.attribute_name} onChange={this.handleChange}></input>
        {field.description && <p class="crayons-field__description">{field.description}</p>}
      </div>
    )
  }

  colorField(field) {
    return (
      <div>
        <label class="crayons-field__label" for="profile[field.attribute_name]">
          {field.label}
        </label>
        <div class="flex items-center w-100 m:w-50">
          <input class="crayons-textfield js-color-field" placeholder_text={field["placeholder_text"]} name={field.attribute_name} id={field.attribute_name}></input>
          <input class="crayons-color-selector js-color-field ml-2" placeholder_text={field["placeholder_text"]} name={field.attribute_name} id={field.attribute_name}></input>
          {field.description && <p class="crayons-field__description">{field.description}</p>}
        </div>
      </div>
    )
  }

  render() {
    const {
      prev,
      slidesCount,
      currentSlideIndex,
      communityConfig,
    } = this.props;
    const { profile_image_90, username, name } = this.user;
    const { canSkip, groups } = this.state;

    const sections = groups.map((group) => {
      return (
        <div class="onboarding-profile-sub-section">
          <h2>{group.name}</h2>
          {
            group.description &&
            (<div class="color-base-60">{group.description})</div>)
          }
          <div>
            {group.profile_fields.map(field => {
              return field.input_type === "check_box" ? this.checkboxField(field)
                    : field.input_type === "color_field" ? this.colorField(field)
                    : this.textField(field)
            })}
          </div>
        </div>
      )
    });

    return (
      <div
        data-testid="onboarding-profile-form"
        className="onboarding-main crayons-modal"
      >
        <div className="crayons-modal__box">
          <Navigation
            prev={prev}
            next={this.onSubmit}
            canSkip={canSkip}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
          />
          <div className="onboarding-content about">
            <header className="onboarding-content-header">
              <h1 className="title">Build your profile</h1>
              <h2
                data-testid="onboarding-profile-subtitle"
                className="subtitle"
              >
                Tell us a little bit about yourself — this is how others will
                see you on {communityConfig.communityName}. You’ll always be
                able to edit this later in your Settings.
              </h2>
            </header>
            <div className="current-user-info">
              <figure className="current-user-avatar-container">
                <img
                  className="current-user-avatar"
                  alt="profile"
                  src={profile_image_90}
                />
              </figure>
              <h3>{name}</h3>
              <p>{username}</p>
            </div>
            <div>
              {sections}
            </div>

          </div>
        </div>
      </div>
    )
  }
}

NewProfileForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
  communityConfig: PropTypes.shape({
    communityName: PropTypes.string.isRequired
  }),
};

export default NewProfileForm;

/* eslint-enable camelcase */
