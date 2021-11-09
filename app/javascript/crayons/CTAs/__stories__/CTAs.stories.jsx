import { h } from 'preact';
import { CTA } from '..';
import SampleIcon from '../../../../assets/images/cog.svg';

export default {
  component: CTA,
  title: 'Components/BETA/CTAs',
  argTypes: {
    variant: {
      options: ['default', 'branded', 'ghost'],
      control: 'select'
    },
  },
};

export const Default = (args) => <CTA {...args} />;
Default.args = {
  variant: 'default',
  href: '#',
  rounded: false,
  children: 'Call To Action',
};

export const Branded = (args) => <CTA {...args} />;
Branded.args = {
  ...Default.args,
  variant: 'branded',
};

export const Ghost = (args) => <CTA {...args} />;
Ghost.args = {
  ...Default.args,
  variant: 'ghost',
};

export const WithIcon = (args) => <CTA {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: SampleIcon,
};
