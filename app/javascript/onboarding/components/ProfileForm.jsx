import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { userData, getContentOfToken, updateOnboarding } from '../utilities';
import Navigation from './Navigation';
import ColorPicker from './ColorPicker';
import TextArea from './TextArea';
import TextInput from './TextInput';

import { FormField } from '@crayons';
import { request } from '@utilities/http';

/* eslint-disable camelcase */
class ProfileForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.handleColorPickerChange = this.handleColorPickerChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.user = userData();
    this.state = {
      groups: [],
      formValues: {},
      canSkip: true,
      last_onboarding_page: 'v2: personal info form',
    };
  }

  componentDidMount() {
    this.getProfielFieldGroups();
    updateOnboarding('v2: personal info form');
  }

  async getProfielFieldGroups() {
    try {
      const response = await request(`/profile_field_groups?onboarding=true`);
      if (response.ok) {
        const data = await response.json();
        this.setState({ groups: data.profile_field_groups });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      this.setState({ error: true, errorMessage: error.toString() });
    }
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
      body: JSON.stringify({
        user: { last_onboarding_page },
        profile: { ...formValues },
      }),
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

    currentFormState[name] = value;
    this.setState({
      formValues: currentFormState,
      canSkip: this.formIsEmpty(currentFormState),
    });
  }

  handleColorPickerChange(e) {
    const { formValues } = { ...this.state };
    const currentFormState = formValues;

    const field = e.target;
    const { name, value } = field;

    let sibling = field.nextElementSibling
      ? field.nextElementSibling
      : field.previousElementSibling;
    sibling.value = value;

    currentFormState[name] = value;
    this.setState({
      formValues: currentFormState,
      canSkip: this.formIsEmpty(currentFormState),
    });
  }

  formIsEmpty(currentFormState) {
    // Once we've derived the new form values, check if the form is empty
    // and use that value to set the `canSkip` property on the state.
    Object.values(currentFormState).filter((v) => v.length > 0).length === 0;
  }

  checkboxField(field) {
    return (
      <FormField variant="checkbox">
        <input
          class="crayons-checkbox"
          type="checkbox"
          name={field.attribute_name}
          id={field.attribute_name}
          onChange={this.handleChange}
        />
        <label class="crayons-field__label" htmlFor={field.attribute_name}>
          {field.label}
        </label>
        {field.description && (
          <p class="crayons-field__description">{field.description}</p>
        )}
      </FormField>
    );
  }

  render() {
    const {
      prev,
      slidesCount,
      currentSlideIndex,
      communityConfig,
    } = this.props;
    const { profile_image_90, username, name } = this.user;
    const { canSkip, groups = [], error, errorMessage } = this.state;

    if (error) {
      return (
        <div class="crayons-notice crayons-notice--danger">
          An error occurred: {errorMessage}
        </div>
      );
    }

    const sections = groups.map((group) => {
      return (
        <div class="onboarding-profile-sub-section">
          <h2>{group.name}</h2>
          {group.description && (
            <div class="color-base-60">{group.description})</div>
          )}
          <div>
            {group.profile_fields.map((field) => {
              return field.input_type === 'check_box' ? (
                this.checkboxField(field)
              ) : field.input_type === 'color_field' ? (
                <ColorPicker
                  field={field}
                  onColorChange={this.handleColorPickerChange}
                />
              ) : field.input_type === 'text_area' ? (
                <TextArea field={field} onFieldChange={this.handleChange} />
              ) : (
                <TextInput field={field} onFieldChange={this.handleChange} />
              );
            })}
          </div>
        </div>
      );
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
            <div>{groups && groups.length > 0 && sections}</div>
          </div>
        </div>
      </div>
    );
  }
}

ProfileForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
  communityConfig: PropTypes.shape({
    communityName: PropTypes.string.isRequired,
  }),
};

export default ProfileForm;

/* eslint-enable camelcase */
