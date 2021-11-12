import { h } from 'preact';
import { Button2 } from '@crayons';
import SampleIcon from '@img/cog.svg';

export default {
  component: Button2,
  title: 'BETA/Buttons',
};

export const Default = (args) => <Button2 {...args} />;
Default.args = {
  primary: false,
  rounded: false,
  destructive: false,
  children: 'Button label',
};

export const Primary = (args) => <Button2 {...args} />;
Primary.args = {
  ...Default.args,
  primary: true,
};

export const WithIcon = (args) => <Button2 {...args} />;
WithIcon.args = {
  ...Default.args,
  icon: SampleIcon,
};
