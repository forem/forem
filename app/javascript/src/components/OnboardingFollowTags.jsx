import { h } from 'preact';
import OnboardingTags from './OnboardingTags';

// component of page 2
const OnboardingFollowTags = ({ userData, allTags, followedTags, handleFollowTag }) => (
  <OnboardingTags
    userData={userData}
    allTags={allTags}
    followedTags={followedTags}
    handleFollowTag={handleFollowTag}
  />
);

export default OnboardingFollowTags;
