import { h } from 'preact';
import { Pill } from '..';
import PillsDoc from './Pills.mdx';
import CakeIcon from '@images/cake.svg';
import XIcon from '@images/x.svg';
import HideIcon from '@images/eye-off.svg';

export default {
  component: Pill,
  title: 'Components/Pills',
  parameters: {
    docs: {
      page: PillsDoc,
    },
  },
  argTypes: {
    element: {
      control: {
        type: 'select',
        options: {
          button: undefined,
          a: 'a',
          span: 'span',
          li: 'li',
        },
      },
      description:
        'Pills can be used in a bunch of different contexts, therefore it is important to use appropriate element to represent it in the markup.',
      table: {
        defaultValue: { summary: 'button' },
      },
    },
    iconLeft: {
      control: false,
      description:
        'If possible, this icon should represent the actual data associated with the Pill.',
      table: {
        defaultValue: { summary: 'LockIcon' },
      },
    },
    iconRight: {
      control: false,
      description:
        'If possible, this icon should represent the action associated with the Pill. If there is no action associated, consider not using this icon.',
      table: {
        defaultValue: { summary: 'XIcon' },
      },
    },
    iconRightDestructive: {
      description:
        'Sometimes clicking a pill may cause a destructive action. When `iconRightDestructive` prop is set to true, it will use "X" icon for `iconRight` value by default, and will also apply appropriate style to it.',
      table: {
        defaultValue: { summary: false },
      },
    },
    tooltip: {
      description:
        "If defined, pill will have a custom tooltip on `:hover` and `:focus`. The tooltip content will form part of the Pill's accessible name unless passed as a `<span>` with `aria-hidden='true'`",
      control: {
        type: 'text',
      },
      table: {
        defaultValue: { summary: undefined },
      },
    },
  },
};

export const Default = (args) => <Pill {...args} />;
Default.args = {
  children: 'Hello world',
  element: undefined,
  iconLeft: undefined,
  iconRight: undefined,
  iconRightDestructive: false,
};

export const WithLeftIcon = (args) => <Pill {...args} />;
WithLeftIcon.args = {
  ...Default.args,
  iconLeft: CakeIcon,
};

export const WithRightIcon = (args) => <Pill {...args} />;
WithRightIcon.args = {
  ...Default.args,
  iconRight: XIcon,
};

export const WithBothIcons = (args) => <Pill {...args} />;
WithBothIcons.args = {
  ...Default.args,
  iconLeft: CakeIcon,
  iconRight: XIcon,
};

export const Destructive = (args) => <Pill {...args} />;
Destructive.args = {
  ...Default.args,
  iconRightDestructive: true,
};

export const DestructiveWithLeftIcon = (args) => <Pill {...args} />;
DestructiveWithLeftIcon.args = {
  ...Default.args,
  iconLeft: CakeIcon,
  iconRightDestructive: true,
};

export const DestructiveWithCustomIcon = (args) => <Pill {...args} />;
DestructiveWithCustomIcon.args = {
  ...Default.args,
  iconRight: HideIcon,
  iconRightDestructive: true,
};

export const WithTooltip = (args) => <Pill {...args} />;
WithTooltip.args = {
  ...Default.args,
  tooltip: 'Tooltip content...',
};
