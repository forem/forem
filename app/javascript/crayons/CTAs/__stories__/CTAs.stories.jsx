import { h } from 'preact';
import { CTA } from '../';
import CTAsDoc from './CTAs.mdx';
import CogIcon from '@images/cog.svg';

export default {
  component: CTA,
  title: 'BETA/Navigation/CTAs',
  parameters: {
    docs: {
      page: CTAsDoc,
    },
  },
  argTypes: {
    variant: {
      control: {
        type: 'select',
        options: {
          default: undefined,
          branded: 'branded',
        },
      },
      description:
        'There are two available variants (styles) to pick from: _default_ and _branded_. The primary difference is color: _default_ uses grey color and _branded_ uses accent color.',
      table: {
        defaultValue: { summary: 'default' },
      },
    },
  },
};

export const Default = (args) => <CTA {...args} />;
Default.args = {
  children: 'Call to action',
};

export const Branded = (args) => <CTA {...args} />;
Branded.args = {
  ...Default.args,
  variant: 'branded',
};

export const DefaultWithIcon = (args) => <CTA {...args} />;
DefaultWithIcon.args = {
  ...Default.args,
  icon: CogIcon,
};

export const BrandedWithIcon = (args) => <CTA {...args} />;
BrandedWithIcon.args = {
  ...Branded.args,
  icon: CogIcon,
};
