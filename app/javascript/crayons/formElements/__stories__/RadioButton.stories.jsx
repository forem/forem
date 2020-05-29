import { h } from 'preact';
import { withKnobs, text, boolean } from '@storybook/addon-knobs/react';
import { action } from '@storybook/addon-actions';
import { RadioButton } from '@crayons';

export default {
  title: '3_Components/Form Components/Radio Button',
  decorators: [withKnobs],
};

export const Default = () => (
  <RadioButton
    name="some-radio-button"
    checked={boolean('checked', false)}
    onClick={action('clicked')}
  />
);

Default.story = {
  name: 'default',
};

export const AdditionalCssClassName = () => (
  <RadioButton
    name="some-radio-button"
    checked={boolean('checked', false)}
    className={text('className', 'mr-10')}
    onClick={action('clicked')}
  />
);

AdditionalCssClassName.story = {
  name: 'additional CSS class',
};
