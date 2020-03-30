import { h } from 'preact';
import { withKnobs, text } from '@storybook/addon-knobs/react';
import { Dropdown } from '@crayons';

import './dropdown-css-helper.scss';

const showDropdownDecorator = (story) => (
  <div className="show-children">{story()}</div>
);

export default {
  title: 'Components/Dropdowns/JSX',
  decorators: [withKnobs, showDropdownDecorator],
};

export const Default = () => (
  <Dropdown>
    Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
    adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
  </Dropdown>
);

Default.story = {
  name: 'default',
};

export const AdditonalCssClasses = () => (
  <Dropdown className={text('className', 'p-6')}>
    Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
    adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
  </Dropdown>
);

AdditonalCssClasses.story = {
  name: 'additional CSS classes',
};
