import { h } from 'preact';
import { Indicator } from '../';
import IndicatorsDoc from './Indicators.mdx';

export default {
  component: Indicator,
  title: 'Components/Indicators',
  parameters: {
    docs: {
      page: IndicatorsDoc,
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

export const Default = (args) => <Indicator {...args} />;
Default.args = {
  children: 'Hello world',
  extraPadding: false,
};

export const VariantInfo = (args) => <Indicator {...args} />;
VariantInfo.args = {
  ...Default.args,
  variant: 'info',
};

export const VariantSuccess = (args) => <Indicator {...args} />;
VariantSuccess.args = {
  ...Default.args,
  variant: 'success',
};

export const VariantWarning = (args) => <Indicator {...args} />;
VariantWarning.args = {
  ...Default.args,
  variant: 'warning',
};

export const VariantDanger = (args) => <Indicator {...args} />;
VariantDanger.args = {
  ...Default.args,
  variant: 'danger',
};

export const ExtraPadding = (args) => <Indicator {...args} />;
ExtraPadding.args = {
  ...Default.args,
  extraPadding: true,
  children: 'Hello world',
};
