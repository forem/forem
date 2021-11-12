import { h } from 'preact';
import { ButtonNew } from '@crayons';
import SampleIcon from '@img/cog.svg';

export default {
  component: ButtonNew,
  title: 'BETA/Buttons',
};

export const Default = (args) => <ButtonNew {...args} />;
Default.args = {
  primary: false,
  rounded: false,
  destructive: false,
  children: 'Button label',
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
