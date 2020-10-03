import { h } from 'preact';
import PropTypes from 'prop-types';
import { useEffect, useState } from 'preact/hooks';
import { userData, getContentOfToken, updateOnboarding } from '../utilities';
import Navigation from './Navigation';
import OnboardingForm from './OnboardingForm';
import OnboardingContentHeader from './OnboardingContentHeader';

const lastOnboardingPage = 'v2: personal info form';

const ProfileForm = ({
  prev,
  slidesCount,
  currentSlideIndex,
  communityConfig,
  next,
}) => {
  const [formValues, setFormValues] = useState({
    summary: '',
    location: '',
    employment_title: '',
    employer_name: '',
  });
  const [canSkip, setCanSkip] = useState(true);

  useEffect(() => {
    updateOnboarding(lastOnboardingPage);
  }, []);

  const onSubmit = () => {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { ...formValues, lastOnboardingPage } }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        next();
      }
    });
  };

  const handleChange = (e) => {
    const currentFormState = formValues;
    const { name, value } = e.target;

    currentFormState[name] = value;

    // Once we've derived the new form values, check if the form is empty
    // and use that value to set the `canSkip` property on the state.
    const formIsEmpty =
      Object.values(currentFormState).filter((v) => v.length > 0).length === 0;
    setFormValues(currentFormState);
    setCanSkip(formIsEmpty);
  };

  const { profile_image_90, username, name } = userData();

  return (
    <div
      data-testid="onboarding-profile-form"
      className="onboarding-main crayons-modal"
    >
      <div className="crayons-modal__box">
        <Navigation
          prev={prev}
          next={onSubmit}
          canSkip={canSkip}
          slidesCount={slidesCount}
          currentSlideIndex={currentSlideIndex}
        />
        <div className="onboarding-content about">
          <OnboardingContentHeader
            communityName={communityConfig.communityName}
          />
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
          <OnboardingForm onChange={handleChange} />
        </div>
      </div>
    </div>
  );
};

ProfileForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
  communityConfig: PropTypes.shape({
    communityName: PropTypes.string.isRequired,
    communityDescription: PropTypes.string.isRequired,
  }),
};

export default ProfileForm;
