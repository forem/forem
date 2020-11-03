import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';

import guidelinesDocs from './guidelines.md';
import componentDocs from './components.md';
import utilityFirstCssDocs from './utility-first-css.md';
import writingCssDocs from './writing-css.md';

export default {
  title: 'Welcome',
};

export const Crayons = () => (
  <div
    className="crayons-card text-styles text-padding"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: guidelinesDocs }}
  />
);

Crayons.story = {
  name: 'Introduction',
};

export const Components = () => (
  <div
    className="crayons-card text-styles text-padding"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: componentDocs }}
  />
);

Components.story = {
  name: 'Components',
};

export const UtilityFirstCss = () => (
  <div
    className="crayons-card text-styles text-padding"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: utilityFirstCssDocs }}
  />
);

UtilityFirstCss.story = {
  name: 'Utility-First CSS',
};

export const WritingCss = () => (
  <div
    className="crayons-card text-styles text-padding"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: writingCssDocs }}
  />
);

WritingCss.story = {
  name: 'Writing CSS',
};
