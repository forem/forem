import { h } from 'preact';
import { withKnobs, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import notes from '../../form-elements.md';
import { RadioButton } from '@crayons';

export default {
  title: 'Components/Form Components/Radio Button',
  decorators: [withKnobs],
  parameters: { notes },
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
