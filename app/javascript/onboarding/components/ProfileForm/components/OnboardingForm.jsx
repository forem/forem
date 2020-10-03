import { h } from 'preact';
import PropTypes from 'prop-types';

const OnboardingForm = ({ onChange }) => (
  <form>
    <label htmlFor="summary">
      Bio
      <textarea
        name="summary"
        id="summary"
        placeholder="Tell us about yourself"
        onChange={onChange}
        maxLength="120"
      />
    </label>
    <label htmlFor="location">
      Where are you located?
      <input
        type="text"
        name="location"
        id="location"
        placeholder="e.g. New York, NY"
        onChange={onChange}
        maxLength="60"
      />
    </label>
    <label htmlFor="employment_title">
      What is your title?
      <input
        type="text"
        name="employment_title"
        id="employment_title"
        placeholder="e.g. Software Engineer"
        onChange={onChange}
        maxLength="60"
      />
    </label>
    <label htmlFor="employer_name">
      Where do you work?
      <input
        type="text"
        name="employer_name"
        id="employer_name"
        placeholder="e.g. Company name, self-employed, etc."
        onChange={onChange}
        maxLength="60"
        className="onboarding-form-input--last"
      />
    </label>
  </form>
);

OnboardingForm.propTypes = {
  onChange: PropTypes.func.isRequired,
};

export { OnboardingForm };
