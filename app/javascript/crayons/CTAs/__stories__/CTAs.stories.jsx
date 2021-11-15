import { h } from 'preact';
import { CTA } from '../';
import CTAsDoc from './CTAs.mdx';
import SampleIcon from '@img/cog.svg';

export default {
  component: CTA,
  title: 'BETA/Navigation/CTAs',
  parameters: {
    docs: {
      page: CTAsDoc,
    },
  },
  argTypes: {
    style: {
      control: {
        type: 'select',
        options: ['default', 'branded'],
      },
      description:
        'There are two available styles to pick from: _default_ and _branded_. The primary difference is color: _default_ uses grey color and _branded_ uses accent color.',
      table: {
        defaultValue: { summary: 'default' },
      },
    },
    rounded: {
      description:
        'By enabling this setting you can turn all corners of the CTA to be fully rounded. We usually use it **only** for CTAs containing **icon without label**.',
      table: {
        defaultValue: { summary: false },
      },
    },
  },
};

export const Default = (args) => <CTA {...args} />;
Default.args = {
  children: 'Call to action',
  style: 'default',
  rounded: false,
};

export const Branded = (args) => <CTA {...args} />;
Branded.args = {
  ...Default.args,
  style: 'branded',
};

export const WithIcon = (args) => <CTA {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: SampleIcon,
};
