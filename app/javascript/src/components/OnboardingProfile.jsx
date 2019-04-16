import { h, render, Component } from 'preact';

// page 1
const OnboardingProfile = ({ onChange }) => {
  return (
    <div className="onboarding-profile-page">
      <div className="onboarding-user-cta">
        Tell the us a bit about yourself ❤️
      </div>
      <div className="onboarding-profile-question">What's your quick bio?</div>
      <input
        name="summary"
        placeholder="e.g. I'm a passionate hacker wizard unicorn ninja"
        maxLength="120"
        onChange={onChange}
      />
      <div className="onboarding-profile-question">Where are you located?</div>
      <input
        name="location"
        placeholder="e.g. New York City"
        maxLength="60"
        onChange={onChange}
      />
      <div className="onboarding-profile-question">What is your title?</div>
      <input
        name="employment_title"
        placeholder="e.g. Frontend developer"
        maxLength="60"
        onChange={onChange}
      />
      <div className="onboarding-profile-question">Where do you work?</div>
      <input
        name="employer_name"
        placeholder="e.g. Google"
        maxLength="60"
        onChange={onChange}
      />
      <div className="onboarding-profile-question">
        What are your core skills/languages?
      </div>
      <input
        name="mostly_work_with"
        placeholder="e.g. JavaScript and MongoDB"
        maxLength="200"
        onChange={onChange}
      />
      <div className="onboarding-profile-question">
        What are you currently learning/playing with?
      </div>
      <input
        name="currently_learning"
        placeholder="e.g. Rust and Docker"
        maxLength="200"
        onChange={onChange}
      />
    </div>
  );
};

export default OnboardingProfile;
