import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Dropdowns/HTML',
};

export const Default = () => (
  <div className="dropdown-trigger-container">
    <a href="/" className="crayons-btn dropdown-trigger">
      Hover to trigger dropdown
    </a>
    <div className="crayons-dropdown">
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </div>
  </div>
);

Default.story = {
  name: 'default',
};

export const AdditonalCssClasses = () => (
  <div className="dropdown-trigger-container">
    <a href="/" className="crayons-btn dropdown-trigger">
      Hover to trigger dropdown
    </a>
    <div className="crayons-dropdown p-6">
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </div>
  </div>
);

AdditonalCssClasses.story = {
  name: 'additional CSS classes',
};
