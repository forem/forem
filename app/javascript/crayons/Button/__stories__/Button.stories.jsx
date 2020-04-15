import { h } from 'preact';
import { withKnobs, object, text, boolean } from '@storybook/addon-knobs/react';
import { action } from '@storybook/addon-actions';
import { Button } from '@crayons';

import '../../storybook-utiltiies/designSystem.scss';

const commonProps = {
  onClick: action('onclick fired'),
  onMouseOver: action('onmouseover fired'),
  onMouseOut: action('onmouseout fired'),
  onFocus: action('onfocus fired'),
  onBlur: action('onblur fired'),
};

export default {
  title: 'Components/Buttons',
  decorator: [withKnobs],
};

export const Default = () => (
  <Button
    icon={object('icon')}
    variant={text('variant')}
    className={text('className')}
    tagName={text('tagName', 'button')}
    url={text('url')}
    buttonType={text('buttonType')}
    disabled={boolean('disabled', false)}
    {...commonProps}
  >
    Hello world!
  </Button>
);

Default.story = {
  name: 'default',
};

export const Secondary = () => (
  <Button
    variant={text('variant', 'secondary')}
    icon={object('icon')}
    className={text('className')}
    tagName={text('tagName', 'button')}
    url={text('url')}
    buttonType={text('buttonType')}
    disabled={boolean('disabled', false)}
    {...commonProps}
  >
    Hello world!
  </Button>
);

Secondary.story = {
  name: 'secondary',
};

export const Outlined = () => (
  <Button
    variant={text('variant', 'outlined')}
    icon={object('icon')}
    className={text('className')}
    tagName={text('tagName', 'button')}
    url={text('url')}
    buttonType={text('buttonType')}
    disabled={boolean('disabled', false)}
    {...commonProps}
  >
    Hello world!
  </Button>
);

Outlined.story = {
  name: 'outlined',
};

export const Danger = () => (
  <Button
    variant={text('variant', 'danger')}
    icon={object('icon')}
    className={text('className')}
    tagName={text('tagName', 'button')}
    url={text('url')}
    buttonType={text('buttonType')}
    disabled={boolean('disabled', false)}
    {...commonProps}
  >
    Hello world!
  </Button>
);

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
    <Button
      icon={object('icon', Icon)}
      variant={text('variant')}
      className={text('className')}
      tagName={text('tagName', 'button')}
      url={text('url')}
      buttonType={text('buttonType')}
      disabled={boolean('disabled', false)}
      {...commonProps}
    >
      Hello world!
    </Button>
  );
};

IconWithText.story = {
  name: 'icon with text',
};

export const IconOnly = () => {
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
    <Button
      icon={object('icon', Icon)}
      variant={text('variant')}
      className={text('className')}
      tagName={text('tagName', 'button')}
      url={text('url')}
      buttonType={text('buttonType')}
      disabled={boolean('disabled', false)}
      {...commonProps}
    />
  );
};

IconOnly.story = {
  name: 'icon only',
};

export const ButtonAsLink = () => (
  <Button
    variant={text('variant')}
    className={text('className')}
    tagName={text('tagName', 'a')}
    icon={object('icon')}
    url={text('url', '#')}
    buttonType={text('buttonType')}
    disabled={boolean('disabled', false)}
    {...commonProps}
  >
    Hello world!
  </Button>
);

ButtonAsLink.story = {
  name: 'button as link',
};
