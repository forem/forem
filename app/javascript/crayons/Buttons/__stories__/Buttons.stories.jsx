import { h } from 'preact';
import ButtonsDoc from './Buttons.mdx';
import { ButtonNew as Button } from '@crayons';
import CogIcon from '@images/cog.svg';

export default {
  component: Button,
  title: 'BETA/Buttons',
  parameters: {
    docs: {
      page: ButtonsDoc,
    },
  },
  argTypes: {
    variant: {
      control: {
        type: 'select',
        options: {
          default: undefined,
          primary: 'primary',
          secondary: 'secondary',
        },
      },
      description:
        'There are three available variants (styles) to pick from: _default_, _primary_ and _secondary_. Please refer to the documentation to better understand the differences in usage.',
      table: {
        defaultValue: { summary: 'default' },
      },
    },
    rounded: {
      description:
        'By enabling this setting you can turn all corners of the button to be fully rounded. We usually use it **only** for buttons containing **icon without label**.',
      table: {
        defaultValue: { summary: false },
      },
    },
    destructive: {
      description:
        'For various destructive actions we can have special styling for button which will add red-ish coloring. Keep in mind we only have two variants available for destructive button: _default_ and _primary_',
      table: {
        defaultValue: { summary: false },
      },
    },
    tooltip: {
      description:
        "If defined, button will have a custom tooltip on `:hover` and `:focus`. The tooltip content will form part of the button's accessible name unless passed as a `<span>` with `aria-hidden='true'`",
      control: {
        type: 'text',
      },
      table: {
        defaultValue: { summary: undefined },
      },
    },
    icon: {
      control: false,
      description:
        'Even though the generated JSX code in this component will have an empty function as prop value (`<Button icon={() => {}}>`), the actual value should be an icon object imported from `@images`. Read more about icons in their dedicated Storybook page.',
      table: {
        defaultValue: { summary: 'CogIcon' },
      },
    },
  },
};

export const Default = (args) => <Button {...args} />;
Default.args = {
  destructive: false,
  children: 'Button label',
  tooltip: undefined,
  rounded: false,
};

export const Primary = (args) => <Button {...args} />;
Primary.args = {
  ...Default.args,
  variant: 'primary',
};

export const Secondary = (args) => <Button {...args} />;
Secondary.args = {
  ...Default.args,
  variant: 'secondary',
};

export const Destructive = (args) => <Button {...args} />;
Destructive.args = {
  ...Default.args,
  destructive: true,
};

export const WithTooltip = (args) => <Button {...args} />;
WithTooltip.args = {
  ...Default.args,
  tooltip: 'Hello world',
};

export const WithIcon = (args) => <Button {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: CogIcon,
};

export const IconOnly = (args) => <Button {...args} />;
IconOnly.args = {
  ...Default.args,
  icon: CogIcon,
  tooltip: 'Button label',
  children: undefined,
};
