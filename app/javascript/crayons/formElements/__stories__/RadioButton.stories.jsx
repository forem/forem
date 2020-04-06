import { h } from 'preact';
import { withKnobs, text, boolean } from '@storybook/addon-knobs/react';
import { RadioButton } from '@crayons';

export default {
  title: 'Components/Form Components/Radio Button',
  decorators: [withKnobs],
};

export const Default = () => (
  <RadioButton name="some-radio-button" checked={boolean('checked', false)} />
);

Default.story = {
  name: 'default',
};

export const AdditionalCssClassName = () => (
  <RadioButton
    name="some-radio-button"
    checked={boolean('checked', false)}
    className={text('className', 'mr-10')}
  />
);

AdditionalCssClassName.story = {
  name: 'additional CSS class',
};
