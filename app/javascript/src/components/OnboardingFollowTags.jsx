import { h } from 'preact';
import PropTypes from 'prop-types';
import OnboardingTags from './OnboardingTags';

// component of page 2
const OnboardingFollowTags = ({ allTags, handleFollowTag }) => (
  <OnboardingTags allTags={allTags} handleFollowTag={handleFollowTag} />
);

OnboardingFollowTags.propTypes = {
  allTags: PropTypes.objectOf().isRequired,
  handleFollowTag: PropTypes.func.isRequired,
};

export default OnboardingFollowTags;
