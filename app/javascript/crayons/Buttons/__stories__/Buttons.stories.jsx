import { h } from 'preact';
import ButtonsDoc from './Buttons.mdx';
import { ButtonNew } from '@crayons';
import SampleIcon from '@img/cog.svg';

export default {
  component: ButtonNew,
  title: 'BETA/Buttons',
  parameters: {
    docs: {
      page: ButtonsDoc,
    },
  },
  argTypes: {
    primary: {
      description:
        'This prop defines whether or not your button will have *primary* style (in practice: high contrast, filled with accent color). Keep in mind ideally there should be only one primary button per entire component, or sometimes even per entire view.',
      table: {
        defaultValue: { summary: false },
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
        'For various destructive actions we can have special styling for button which will add red-ish coloring.',
      table: {
        defaultValue: { summary: false },
      },
    },
    tooltip: {
      description: 'If defined, button will have a custom tooltip on `:hover`.',
      control: {
        type: 'text',
      },
      table: {
        defaultValue: { summary: undefined },
      },
    },
  },
};

export const Default = (args) => <ButtonNew {...args} />;
Default.args = {
  primary: false,
  destructive: false,
  children: 'Button label',
  tooltip: undefined,
  rounded: false,
};

export const Primary = (args) => <ButtonNew {...args} />;
Primary.args = {
  ...Default.args,
  primary: true,
};

export const WithIcon = (args) => <ButtonNew {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: SampleIcon,
};
