import { h } from 'preact';
import { Toggle } from '..';
import ToggleDoc from './Toggles.mdx';

export default {
  component: Toggle,
  title: 'Components/Form Elements/Toggles',
  parameters: {
    docs: {
      page: ToggleDoc,
    },
  },
  argTypes: {
    checked: {
      description:
        'In general Toggle is just a `checkbox` wrapped in more fancy package. And the `checked` prop is the only one affecting visuals of the toggle.',
      table: {
        defaultValue: { summary: false },
      },
    },
    description: {
      description:
        'All form elements should have description provided for accessibility reasons. This will only be accessible to screen readers.',
      control: {
        type: 'text',
      },
      table: {
        defaultValue: { summary: undefined },
      },
    },
  },
};

export const Default = (args) => <Toggle {...args} />;
Default.args = {
  description: 'This is an a11y description',
  checked: false,
};

export const Checked = (args) => <Toggle {...args} />;
Checked.args = {
  ...Default.args,
  checked: true,
};
