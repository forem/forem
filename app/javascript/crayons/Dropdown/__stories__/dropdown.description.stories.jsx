import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Dropdowns',
};

export const Description = () => (
  <div className="container">
    <h2>Dropdowns</h2>
    <p>
      Dropdowns should have position relative to it’s trigger. They can be used
      for some 2nd level navigations, contextual configurations, etc...
    </p>
    <p>Dropdowns should not be bigger than 320px.</p>
    <p>Dropdown default padding should be dependent on width:</p>
    <ul>
      <li>&lt;250px: 16px</li>
      <li>251 - 320px: 24px</li>
    </ul>
    <p>
      FYI: Dropdowns use “Box” component as background, with Level 3 elevation.
    </p>
  </div>
);

Description.story = {
  name: 'description',
};
