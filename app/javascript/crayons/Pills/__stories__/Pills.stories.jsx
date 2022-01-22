import { h } from 'preact';
import { Pill } from '..';
import PillsDoc from './Pills.mdx';

export default {
  component: Pill,
  title: 'BETA/Pills',
  parameters: {
    docs: {
      page: PillsDoc,
    },
  },
  argTypes: {
    variant: {
      control: {
        type: 'select',
        options: {
          default: undefined,
          info: 'info',
          success: 'success',
          warning: 'warning',
          danger: 'danger',
        },
      },
      description:
        'There are bunch of available variants (styles) to pick from. The primary difference is color but each color should be used for different purpose. Read Docs for more info.',
      table: {
        defaultValue: { summary: 'default' },
      },
    },
    extraPadding: {
      description:
        'Indicators are "tight" by default which means they have very little padding. This will gently increase the padding so it looks more loose.',
      table: {
        defaultValue: { summary: false },
      },
    },
  },
};

export const Default = (args) => <Pill {...args} />;
Default.args = {
  children: 'Hello world',
  extraPadding: false,
};

export const VariantInfo = (args) => <Pill {...args} />;
VariantInfo.args = {
  ...Default.args,
  variant: 'info',
};
