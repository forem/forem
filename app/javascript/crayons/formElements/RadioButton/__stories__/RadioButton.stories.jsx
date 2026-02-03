import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import notes from '../../form-elements.mdx';
import { RadioButton } from '@crayons';

export default {
  title: 'Components/Form Elements/Radio Button',
  component: RadioButton,
  parameters: { notes },
  argTypes: {
    checked: {
      control: { type: 'boolean' },
    },
    className: {
      control: { type: 'text' },
    },
  },
  args: {
    checked: false,
    className: '',
  },
};

export const Default = (args) => (
  <RadioButton
    name="some-radio-button"
    checked={args.checked}
    onClick={action('clicked')}
  />
);

Default.storyName = 'default';

export const AdditionalCssClassName = (args) => (
  <RadioButton
    name="some-radio-button"
    checked={args.checked}
    className="mr-10"
    onClick={action('clicked')}
  />
);

AdditionalCssClassName.storyName = 'additional CSS class';
