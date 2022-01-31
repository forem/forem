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
    descriptionIcon: {
      control: false,
      description:
        'If possible, this icon should represent the actual data associated with the Pill.',
      table: {
        defaultValue: { summary: 'LockIcon' },
      },
    },
    actionIcon: {
      control: false,
      description:
        'If possible, this icon should represent the action associated with the Pill.',
      table: {
        defaultValue: { summary: 'XIcon' },
      },
    },
    destructiveActionIcon: {
      description:
        'Sometimes clicking a pill may cause a destructive action. When `destructiveActionIcon` prop is set to true, it will use "X" icon for `actionIcon` value by default, and will also apply appropriate style to it.',
      table: {
        defaultValue: { summary: false },
      },
    },
    noAction: {
      description:
        'In some edge cases (very edge...) we may not want to trigger any action. Enabling this prop will add appropriate attributes to the Pill to still make it accessible for assistive technologies.',
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
  descriptionIcon: undefined,
  actionIcon: undefined,
  destructiveActionIcon: false,
  noAction: false,
};

export const WithDescriptionIcon = (args) => <Pill {...args} />;
WithDescriptionIcon.args = {
  ...Default.args,
  descriptionIcon: CakeIcon,
};

export const WithActionIcon = (args) => <Pill {...args} />;
WithActionIcon.args = {
  ...Default.args,
  actionIcon: XIcon,
};

export const WithBothIcons = (args) => <Pill {...args} />;
WithBothIcons.args = {
  ...Default.args,
  descriptionIcon: CakeIcon,
  actionIcon: XIcon,
};

export const Destructive = (args) => <Pill {...args} />;
Destructive.args = {
  ...Default.args,
  destructiveActionIcon: true,
};

export const DestructiveWithDescriptionIcon = (args) => <Pill {...args} />;
DestructiveWithDescriptionIcon.args = {
  ...Default.args,
  descriptionIcon: CakeIcon,
  destructiveActionIcon: true,
};

export const DestructiveWithCustomIcon = (args) => <Pill {...args} />;
DestructiveWithCustomIcon.args = {
  ...Default.args,
  actionIcon: HideIcon,
  destructiveActionIcon: true,
};

export const WithTooltip = (args) => <Pill {...args} />;
WithTooltip.args = {
  ...Default.args,
  tooltip: 'Tooltip content...',
};

export const NoAction = (args) => <Pill {...args} />;
NoAction.args = {
  ...Default.args,
  noAction: true,
};

export const NoActionWithTooltip = (args) => <Pill {...args} />;
NoActionWithTooltip.args = {
  ...Default.args,
  noAction: true,
  tooltip: 'Explain why no action...',
};
