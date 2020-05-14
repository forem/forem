import { h } from 'preact';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

export const TodaysPodcasts = ({ children }) => (
  <div className="crayons-story">
    <div class="crayons-story__body">
      <h3 class="crayons-story__headline"><a href="/pod">Today&apos;s Podcasts</a></h3>
      {children}
    </div>
  </div>
);

TodaysPodcasts.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

TodaysPodcasts.displayName = 'TodaysPodcasts';
