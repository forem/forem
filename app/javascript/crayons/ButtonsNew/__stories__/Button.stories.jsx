import { h } from 'preact';
import { Button } from '../';

export default {
  component: Button,
  title: 'Components/Button [BETA]',
  argTypes: {
    rounded: {
      control: { type: 'boolean' },
    },
    destructive: {
      control: { type: 'boolean' },
    },
  },
};

export const Primary = (args) => <Button {...args}>Primary button</Button>;
Primary.args = {
  rounded: false,
  destructive: false,
};

export const Secondary = (args) => (
  <Button variant="secondary" {...args}>
    Secondary button
  </Button>
);
Secondary.args = {
  rounded: false,
  destructive: false,
};
