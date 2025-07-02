import { h, Component } from 'preact'
import PropTypes from 'prop-types'

import { userData, updateOnboarding } from '../utilities'

import { ProfileImage } from './ProfileForm/ProfileImage'
import { Navigation } from './Navigation'
import { TextArea } from './ProfileForm/TextArea'
import { TextInput } from './ProfileForm/TextInput'
import { CheckBox } from './ProfileForm/CheckBox'

import { request } from '@utilities/http'

/* eslint-disable camelcase */
export class ProfileForm extends Component {
  constructor(props) {
    super(props)

    this.handleFieldChange = this.handleFieldChange.bind(this)
    this.handleColorPickerChange = this.handleColorPickerChange.bind(this)
    this.onSubmit = this.onSubmit.bind(this)
    this.user = userData()

    this.state = {
      groups: [],
      formValues: {
        username: this.user.username,
        name: this.user.name,
        profile_image_90: this.user.profile_image_90,
      },
      canSkip: false,
      last_onboarding_page: 'v2: personal info form',
      profile_image_90: this.user.profile_image_90,
    }
  }

  componentDidMount() {
    this.getProfileFieldGroups()
    updateOnboarding('v2: personal info form')
  }

  async getProfileFieldGroups() {
    try {
      const response = await request(`/profile_field_groups?onboarding=true`)
      if (response.ok) {
        const data = await response.json()
        this.setState({ groups: data.profile_field_groups })
      } else {
        throw new Error(response.statusText)
      }
    } catch (error) {
      this.setState({ error: true, errorMessage: error.toString() })
    }
  }

  async onSubmit() {
    const { formValues, last_onboarding_page } = this.state
    const { username, name, profile_image_90, ...newFormValues } = formValues

    try {
      const response = await request('/onboarding', {
        method: 'PATCH',
        body: {
          user: { last_onboarding_page, profile_image_90, username, name },
          profile: { ...newFormValues },
        },
      })

      if (!response.ok) throw response

      this.props.next()
    } catch (error) {
      Honeybadger.notify(error)
      let errorMessage = 'Unable to continue, please try again.'

      if (error.status === 422) {
        const errorData = await error.json()
        errorMessage = errorData.errors
      }

      this.setState({ error: true, errorMessage })
    }
  }

  handleFieldChange(e) {
    const { name, value } = e.target
    this.setState((prev) => {
      const formValues = { ...prev.formValues, [name]: value }
      return {
        formValues,
        canSkip: this.formIsEmpty(formValues),
      }
    })
  }

  handleColorPickerChange(e) {
    const field = e.target
    const { name, value } = field
    const sibling = field.nextElementSibling || field.previousElementSibling
    if (sibling) sibling.value = value

    this.setState((prev) => {
      const formValues = { ...prev.formValues, [name]: value }
      return {
        formValues,
        canSkip: this.formIsEmpty(formValues),
      }
    })
  }

  formIsEmpty(currentFormState) {
    return Object.values(currentFormState).filter((v) => v.length > 0)
      .length === 0
  }

  renderAppropriateFieldType(field) {
    switch (field.input_type) {
      case 'check_box':
        return (
          <CheckBox
            key={field.id}
            field={field}
            onFieldChange={this.handleFieldChange}
          />
        )
      case 'text_area':
        return (
          <TextArea
            key={field.id}
            field={field}
            onFieldChange={this.handleFieldChange}
          />
        )
      default:
        return (
          <TextInput
            key={field.id}
            field={field}
            onFieldChange={this.handleFieldChange}
          />
        )
    }
  }

  onProfileImageUrlChange = (url) => {
    this.setState({ profile_image_90: url }, () => {
      this.handleFieldChange({
        target: { name: 'profile_image_90', value: url },
      })
    })
  }

  render() {
    const {
      prev,
      slidesCount,
      currentSlideIndex,
      communityConfig,
    } = this.props
    const { canSkip, groups = [], error, errorMessage } = this.state
    const SUMMARY_MAXLENGTH = 200
    const summaryCharacters =
      this.state.formValues.summary?.length || 0

    // text inputs for the onboarding groups
    const sections = groups.map((group) => (
      <div key={group.id} class="onboarding-profile-sub-section">
        <h2>{group.name}</h2>
        {group.description && (
          <div class="color-base-60">{group.description}</div>
        )}
        <div>
          {group.profile_fields.map((field) =>
            this.renderAppropriateFieldType(field)
          )}
        </div>
      </div>
    ))

    const { username, name } = this.user

    return (
      <div
        data-testid="onboarding-profile-form"
        className="onboarding-main crayons-modal crayons-modal--large"
      >
        <div
          className="crayons-modal__box"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          {error && (
            <div
              role="alert"
              class="crayons-notice crayons-notice--danger m-2"
            >
              An error occurred: {errorMessage}
            </div>
          )}
          <div className="onboarding-content about">
            <header className="onboarding-content-header">
              <h1 id="title" className="title">
                Build your profile
              </h1>
              <h2
                id="subtitle"
                data-testid="onboarding-profile-subtitle"
                className="subtitle"
              >
                Tell us a little bit about yourself — this is how others
                will see you on {communityConfig.communityName}. You’ll
                always be able to edit this later in your Settings.
              </h2>
            </header>

            {/* Profile image + built‐in name prop */}
            <div className="onboarding-profile-sub-section mt-8">
              <ProfileImage
                onMainImageUrlChange={this.onProfileImageUrlChange}
                mainImage={this.state.profile_image_90}
                userId={this.user.id}
                name={name}
              />
            </div>

            {/* NEW: Name field */}
            <div className="onboarding-profile-sub-section">
              <TextInput
                field={{
                  attribute_name: 'name',
                  label: 'Name',
                  default_value: name,
                  required: true,
                  maxLength: 50,
                  placeholder_text: 'Your full name',
                  description: '',
                  input_type: 'text',
                }}
                onFieldChange={this.handleFieldChange}
              />
            </div>

            {/* existing Username field */}
            <div className="onboarding-profile-sub-section">
              <TextInput
                field={{
                  attribute_name: 'username',
                  label: 'Username',
                  default_value: username,
                  required: true,
                  maxLength: 20,
                  placeholder_text: 'johndoe',
                  description: '',
                  input_type: 'text',
                }}
                onFieldChange={this.handleFieldChange}
              />
            </div>

            {/* Bio */}
            <div className="onboarding-profile-sub-section">
              <TextArea
                field={{
                  attribute_name: 'summary',
                  label: 'Bio',
                  placeholder_text:
                    'Tell us a little about yourself',
                  required: false,
                  maxLength: SUMMARY_MAXLENGTH,
                  description: '',
                  input_type: 'text_area',
                }}
                onFieldChange={this.handleFieldChange}
              />
              <p
                id="summary-description"
                class="crayons-field__description align-right"
              >
                <span
                  class="screen-reader-only"
                  aria-live="polite"
                >
                  Remaining characters:{' '}
                  {SUMMARY_MAXLENGTH - summaryCharacters}
                </span>
                <span id="summary-characters">
                  {summaryCharacters}/{SUMMARY_MAXLENGTH}
                </span>
              </p>
            </div>

            {sections}
          </div>

          <Navigation
            prev={prev}
            next={this.onSubmit}
            canSkip={canSkip}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
            hidePrev
          />
        </div>
      </div>
    )
  }
}

ProfileForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired,
  communityConfig: PropTypes.shape({
    communityName: PropTypes.string.isRequired,
  }),
}
/* eslint-enable camelcase */
