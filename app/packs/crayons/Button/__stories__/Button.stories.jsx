import { h } from 'preact';
import {
  withKnobs,
  object,
  text,
  boolean,
  select,
} from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import notes from './buttons.md';
import { Button } from '@crayons';
import '../../storybook-utilities/designSystem.scss';

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
  parameters: {
    notes,
  },
};

export const Default = () => (
  <Button
    variant={select(
      'variant',
      {
        Primary: 'primary',
        Secondary: 'secondary',
        Outlined: 'outlined',
        Danger: 'danger',
        Ghost: 'ghost',
        'Ghost Brand': 'ghost-brand',
        'Ghost Dimmed': 'ghost-dimmed',
        'Ghost Success': 'ghost-success',
        'Ghost Warning': 'ghost-warning',
        'Ghost Danger': 'ghost-danger',
      },
      'primary',
    )}
    size={select(
      'size',
      {
        Small: 's',
        Default: 'default',
        Large: 'l',
        'Extra Large': 'xl',
      },
      'default',
    )}
    contentType={select(
      'contentType',
      {
        Text: 'text',
        'Icon + Text': 'icon-left',
        'Text + Icon': 'icon-right',
        Icon: 'icon',
        'Icon Rounded': 'icon-rounded',
      },
      'text',
    )}
    icon={object('icon')}
    inverted={boolean('inverted', false)}
    className={text('className')}
    tagName={select(
      'tagName',
      {
        Button: 'button',
        A: 'a',
      },
      'button',
    )}
    url={text('url')}
    buttonType={text('buttonType')}
    disabled={boolean('disabled', false)}
    {...commonProps}
  >
    Hello world!
  </Button>
);

Default.story = {
  name: 'Buttons',
};

export const ButtonWithIcon = () => {
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
      variant={select(
        'variant',
        {
          Primary: 'primary',
          Secondary: 'secondary',
          Outlined: 'outlined',
          Danger: 'danger',
          Ghost: 'ghost',
          'Ghost Brand': 'ghost-brand',
          'Ghost Dimmed': 'ghost-dimmed',
          'Ghost Success': 'ghost-success',
          'Ghost Warning': 'ghost-warning',
          'Ghost Danger': 'ghost-danger',
        },
        'primary',
      )}
      size={select(
        'size',
        {
          Small: 's',
          Default: 'default',
          Large: 'l',
          'Extra Large': 'xl',
        },
        'default',
      )}
      contentType={select(
        'contentType',
        {
          Text: 'text',
          'Icon + Text': 'icon-left',
          'Text + Icon': 'icon-right',
          Icon: 'icon',
          'Icon Rounded': 'icon-rounded',
        },
        'icon-left',
      )}
      icon={object('icon', Icon)}
      inverted={boolean('inverted', false)}
      className={text('className')}
      tagName={select(
        'tagName',
        {
          Button: 'button',
          A: 'a',
        },
        'button',
      )}
      url={text('url')}
      buttonType={text('buttonType')}
      disabled={boolean('disabled', false)}
      {...commonProps}
    >
      Hello world!
    </Button>
  );
};

ButtonWithIcon.story = {
  name: 'Buttons with Icon',
};
