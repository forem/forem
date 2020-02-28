import { h } from 'preact';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

export const TodaysPodcasts = ({ children }) => (
  <div className="single-article single-article-podcast-div">
    <h3>
      <a href="/pod">Today&apos;s Podcasts</a>
    </h3>
    {children}
  </div>
);

TodaysPodcasts.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

TodaysPodcasts.displayName = 'TodaysPodcasts';
