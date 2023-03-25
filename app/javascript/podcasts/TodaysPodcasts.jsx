import { h } from 'preact';
import { defaultChildrenPropTypes } from '../common-prop-types';

export const TodaysPodcasts = ({ children }) => (
  <div className="crayons-story">
    <div className="crayons-story__body">
      <h3 className="crayons-story__headline">
        <a href="/pod">Свіжі випуски подкастів</a>
      </h3>
      {children}
    </div>
  </div>
);

TodaysPodcasts.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

TodaysPodcasts.displayName = 'TodaysPodcasts';
