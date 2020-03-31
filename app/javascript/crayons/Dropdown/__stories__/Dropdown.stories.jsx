import { h } from 'preact';
import { withKnobs, text } from '@storybook/addon-knobs/react';
import { Dropdown } from '@crayons';

import './dropdown-css-helper.scss';

export default {
  title: 'Components/Dropdowns/JSX',
  decorators: [withKnobs],
};

export const Default = () => (
  <div className="dropdown-trigger-container">
    <a href="/" className="crayons-btn dropdown-trigger">
      Hover to trigger dropdown
    </a>
    <Dropdown className={text('className', 'mb-2')}>
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </Dropdown>
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
    <Dropdown className={text('className', 'p-6')}>
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </Dropdown>
  </div>
);

AdditonalCssClasses.story = {
  name: 'additional CSS classes',
};
