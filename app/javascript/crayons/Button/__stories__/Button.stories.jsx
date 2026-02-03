import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import notes from './buttons.mdx';
import { Button } from '@crayons';
import '../../storybook-utilities/designSystem.scss';

const commonProps = {
  onClick: action('onclick fired'),
  onMouseOver: action('onmouseover fired'),
  onMouseOut: action('onmouseout fired'),
  onFocus: action('onfocus fired'),
  onBlur: action('onblur fired'),
};

const variantOptions = {
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
};

const sizeOptions = {
  Small: 's',
  Default: 'default',
  Large: 'l',
  'Extra Large': 'xl',
};

const contentTypeOptions = {
  Text: 'text',
  'Icon + Text': 'icon-left',
  'Text + Icon': 'icon-right',
  Icon: 'icon',
  'Icon Rounded': 'icon-rounded',
};

const tagNameOptions = {
  Button: 'button',
  A: 'a',
};

export default {
  title: 'Deprecated/Buttons',
  component: Button,
  parameters: {
    notes,
  },
  argTypes: {
    variant: {
      control: { type: 'select' },
      options: Object.values(variantOptions),
      mapping: variantOptions,
    },
    size: {
      control: { type: 'select' },
      options: Object.values(sizeOptions),
      mapping: sizeOptions,
    },
    contentType: {
      control: { type: 'select' },
      options: Object.values(contentTypeOptions),
      mapping: contentTypeOptions,
    },
    icon: {
      control: { type: 'object' },
    },
    inverted: {
      control: { type: 'boolean' },
    },
    className: {
      control: { type: 'text' },
    },
    tagName: {
      control: { type: 'select' },
      options: Object.values(tagNameOptions),
      mapping: tagNameOptions,
    },
    url: {
      control: { type: 'text' },
    },
    buttonType: {
      control: { type: 'text' },
    },
    disabled: {
      control: { type: 'boolean' },
    },
  },
  args: {
    variant: 'primary',
    size: 'default',
    contentType: 'text',
    icon: undefined,
    inverted: false,
    className: '',
    tagName: 'button',
    url: '',
    buttonType: '',
    disabled: false,
  },
};

export const Default = (args) => (
  <Button
    variant={args.variant}
    size={args.size}
    contentType={args.contentType}
    icon={args.icon}
    inverted={args.inverted}
    className={args.className}
    tagName={args.tagName}
    url={args.url}
    buttonType={args.buttonType}
    disabled={args.disabled}
    {...commonProps}
  >
    Hello world!
  </Button>
);

Default.storyName = 'Buttons';

export const ButtonWithIcon = (args) => {
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
      variant={args.variant}
      size={args.size}
      contentType="icon-left"
      icon={Icon}
      inverted={args.inverted}
      className={args.className}
      tagName={args.tagName}
      url={args.url}
      buttonType={args.buttonType}
      disabled={args.disabled}
      {...commonProps}
    >
      Hello world!
    </Button>
  );
};

ButtonWithIcon.storyName = 'Buttons with Icon';
