import { h } from 'preact';
import { Button } from '..';
import SampleIcon from '../../../../assets/images/cog.svg';

export default {
  component: Button,
  title: 'BETA/Buttons',
};

export const Default = (args) => <Button {...args} />;
Default.args = {
  primary: false,
  rounded: false,
  destructive: false,
  children: 'Button label',
};

export const Primary = (args) => <Button {...args} />;
Primary.args = {
  ...Default.args,
  primary: true
};

export const WithIcon = (args) => <Button {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: SampleIcon,
};
