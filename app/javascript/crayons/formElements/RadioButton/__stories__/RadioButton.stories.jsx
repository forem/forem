import { h } from 'preact';
import { withKnobs, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import notes from '../../form-elements.mdx';
import { RadioButton } from '@crayons';

export default {
  title: 'Components/Form Elements/Radio Button',
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

Default.storyName = 'default';

export const AdditionalCssClassName = () => (
  <RadioButton
    name="some-radio-button"
    checked={boolean('checked', false)}
    className={text('className', 'mr-10')}
    onClick={action('clicked')}
  />
);

AdditionalCssClassName.storyName = 'additional CSS class';
