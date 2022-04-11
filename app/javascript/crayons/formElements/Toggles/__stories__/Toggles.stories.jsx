import { h } from 'preact';
import { Toggle } from '..';
import ToggleDoc from './Toggles.mdx';

export default {
  component: Toggle,
  title: 'Components/Form Elements/Toggles',
  decorators: [
    (story) => (
      <label class="flex gap-2">
        {story()}
        Remember: form elements should be wrapped with labels!
      </label>
    ),
  ],
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
  },
};

export const Default = (args) => <Toggle {...args} />;
Default.args = {
  checked: false,
};

export const Checked = (args) => <Toggle {...args} />;
Checked.args = {
  checked: true,
};
