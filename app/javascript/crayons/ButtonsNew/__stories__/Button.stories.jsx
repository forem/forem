import { h } from 'preact';
// import notes from './buttons.md';
import { Button } from '../';
import '../../storybook-utilities/designSystem.scss';

export default {
  component: Button,
  title: 'Components/Button',
  argTypes: {
    variant: {
      options: ['primary', 'secondary'],
      control: { type: 'select' },
    },
    rounded: {
      control: { type: 'boolean' },
    },
  },
};

export const Primary = () => <Button>Primary button</Button>;

export const Secondary = () => (
  <Button variant="secondary">Primary button</Button>
);
