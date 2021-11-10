import { h } from 'preact';
import { CTA } from '../';
import SampleIcon from '../../../../assets/images/cog.svg';

export default {
  component: CTA,
  title: 'BETA/Navigation/CTAs',
  argTypes: {
    variant: {
      control: {
        type: 'select',
        options: ['default', 'branded']
      }
    }
  }
};

export const Default = (args) => <CTA {...args} />;
Default.args = {
  children: "Call to action",
  variant: 'default',
  rounded: false,
};

export const Branded = (args) => <CTA {...args} />;
Branded.args = {
  ...Default.args,
  variant: 'branded',
};

export const WithIcon = (args) => <CTA {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: SampleIcon,
};
