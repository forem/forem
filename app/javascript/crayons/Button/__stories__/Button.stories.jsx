import { h } from 'preact';
import { withKnobs, object, text } from '@storybook/addon-knobs/react';
import {
  Button,
  DangerButton,
  OutlinedButton,
  SecondaryButton,
} from '@crayons';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Buttons/JSX',
  decorator: [withKnobs],
};

export const Default = () => <Button>Hello world!</Button>;

Default.story = {
  name: 'default',
};

export const Secondary = () => <SecondaryButton>Hello world!</SecondaryButton>;

Secondary.story = {
  name: 'secondary',
};

export const Outlined = () => <OutlinedButton>Hello world!</OutlinedButton>;

Outlined.story = {
  name: 'outlined',
};

export const Danger = () => <DangerButton>Hello world!</DangerButton>;

Danger.story = {
  name: 'danger',
};

export const IconWithText = () => {
  const Icon = () => (
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
  );

  return (
    <Button icon={Icon} variant={text('variant')}>
      Hello world!
    </Button>
  );
};

IconWithText.story = {
  name: 'icon with text',
};

export const KitchenSink = () => (
  <Button
    variant={text('variant')}
    className={text('className')}
    as={text('as', 'button')}
    icon={object('icon')}
  >
    Hello world!
  </Button>
);

KitchenSink.story = {
  name: 'kitchen sink',
};
