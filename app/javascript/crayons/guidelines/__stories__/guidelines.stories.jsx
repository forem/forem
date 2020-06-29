import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';

import guidelinesDocs from './guidelines.md';
import componentDocs from './components.md';
import stylingDocs from './styling.md';

export default {
  title: '1_Guidelines',
};

export const Crayons = () => (
  <div
    className="container"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: guidelinesDocs }}
  />
);

Crayons.story = {
  name: '1.1_Crayons',
};

export const Components = () => (
  <div
    className="container"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: componentDocs }}
  />
);

Components.story = {
  name: '1.2_Components',
};

export const Styling = () => (
  <div
    className="container"
    // eslint-disable-next-line react/no-danger
    dangerouslySetInnerHTML={{ __html: stylingDocs }}
  />
);

Styling.story = {
  name: '1.3_Styling',
};
