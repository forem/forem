import { h } from 'preact';
import PropTypes from 'prop-types';

const OnboardingContentHeader = ({ communityName }) => (
  <header className="onboarding-content-header">
    <h1 className="title">Build your profile</h1>
    <h2 data-testid="onboarding-profile-subtitle" className="subtitle">
      Tell us a little bit about yourself — this is how others will see you on{' '}
      {communityName}. You’ll always be able to edit this later in your
      Settings.
    </h2>
  </header>
);

OnboardingContentHeader.propTypes = {
  communityName: PropTypes.string.isRequired,
};

export { OnboardingContentHeader };
