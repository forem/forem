import { h } from 'preact';
import { defaultChildrenPropTypes } from '../common-prop-types';
import { i18next } from '@utilities/locale';

export const TodaysPodcasts = ({ children }) => (
  <div className="crayons-story">
    <div className="crayons-story__body">
      <h3 className="crayons-story__headline">
        <a href="/pod">{i18next.t('podcasts.today')}</a>
      </h3>
      {children}
    </div>
  </div>
);

TodaysPodcasts.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

TodaysPodcasts.displayName = 'TodaysPodcasts';
