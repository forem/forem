import { h } from 'preact';
import PropTypes from 'prop-types';
import OnboardingSingleTag from './OnboardingSingleTag';

// page 2
function OnboardingTags({ allTags, handleFollowTag }) {
  const tags = allTags.map(tag => {
    return (
      <OnboardingSingleTag
        key={tag.id}
        tag={tag}
        onTagClick={handleFollowTag.bind(this, tag)} // eslint-disable-line react/jsx-no-bind
      />
    );
  });

  return (
    <div className="tags-slide">
      <div className="onboarding-user-cta">Personalize your home feed</div>
      <div className="tags-col-container">{tags}</div>
    </div>
  );
}

OnboardingTags.propTypes = {
  handleFollowTag: PropTypes.func.isRequired,
  allTags: PropTypes.objectOf().isRequired,
};

export default OnboardingTags;
