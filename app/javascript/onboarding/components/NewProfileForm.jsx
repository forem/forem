import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { userData, getContentOfToken, updateOnboarding } from '../utilities';
import Navigation from './Navigation';

/* eslint-disable camelcase */
class NewProfileForm extends Component {
  constructor(props) {
    super(props);

    this.user = userData();
    this.state = {
      groups: []
    };
  }

  componentDidMount() {
    fetch('/profile_field_groups?onboarding=true')
      .then((response) => response.json())
      .then((data) => {
        this.setState({ groups: data.profile_field_groups });
      });

    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: { last_onboarding_page: 'v2: new personal info form' },
      }),
      credentials: 'same-origin',
    });
  }

  checkboxField(field) {
    return (
      <div class="crayons-field crayons-field--checkbox">
        <input class="crayons-checkbox" type="checkbox" name="profile[field.attribute_name]" id="profile[field.attribute_name]"></input>
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
        <input class="crayons-textfield" placeholder_text={field["placeholder_text"]} name="profile[field.attribute_name]" id="profile[field.attribute_name]"></input>
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
          <input class="crayons-textfield js-color-field" placeholder_text={field["placeholder_text"]} name="profile[field.attribute_name]" id="profile[field.attribute_name]"></input>
          <input class="crayons-color-selector js-color-field ml-2" placeholder_text={field["placeholder_text"]} name="profile[field.attribute_name]" id="profile[field.attribute_name]"></input>
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
