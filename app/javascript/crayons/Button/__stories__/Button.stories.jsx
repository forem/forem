import { h } from 'preact';
import { withKnobs, boolean } from '@storybook/addon-knobs/react';
import { Button } from '@crayons';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Buttons/JSX',
  decorator: [withKnobs],
};

export const Default = () => <Button>Hello world!</Button>;

Default.story = {
  name: 'default',
};

export const FullButton = () => <Button isFull>Hello world!</Button>;

FullButton.story = {
  name: 'full',
};

export const SecondaryButton = () => <Button isSecondary>Hello world!</Button>;

SecondaryButton.story = {
  name: 'secondary',
};

export const OutlinedButton = () => <Button isOutlined>Hello world!</Button>;

OutlinedButton.story = {
  name: 'outlined',
};

export const DangerButton = () => <Button isDanger>Hello world!</Button>;

DangerButton.story = {
  name: 'danger',
};

export const IconOnLeftButton = () => (
  <Button hasIconOnLeft isSecondary={boolean('isSecondary', false)}>
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
    Hello world!
  </Button>
);

IconOnLeftButton.story = {
  name: 'icon on left',
};
