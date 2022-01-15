import { h } from 'preact';
import { Link } from '..';
import LinksDoc from './Links.mdx';
import CogIcon from '@images/cog.svg';

export default {
  component: Link,
  title: 'Components/Navigation/Links',
  parameters: {
    docs: {
      page: LinksDoc,
    },
  },
  argTypes: {
    variant: {
      control: {
        type: 'select',
        options: {
          default: undefined,
          branded: 'branded',
        },
      },
      description:
        'There are two available variants (styles) to pick from: _default_ and _branded_. The primary difference is color: _default_ uses grey color and _branded_ uses accent color.',
      table: {
        defaultValue: { summary: 'default' },
      },
    },
    block: {
      description:
        'By adding this prop your link will turn from inline to block one (it will be visually heavier - having some extra padding and taking all available width).',
      table: {
        defaultValue: { summary: false },
      },
    },
    rounded: {
      description:
        'By enabling this setting you can turn all corners of the link to be fully rounded. We usually use it **only** for block links containing **icon without label**.',
      table: {
        defaultValue: { summary: false },
      },
    },
    icon: {
      control: false,
      description:
        'Even though the generated JSX code in this component will have an empty function as prop value (`<Link icon={() => {}}>`), the actual value should be an icon object imported from `@images`. Read more about icons in their dedicated Storybook page.',
      table: {
        defaultValue: { summary: 'CogIcon' },
      },
    },
  },
};

export const Inline = (args) => <Link {...args} />;
Inline.args = {
  block: false,
  rounded: false,
  children: 'Inline link',
};

export const InlineBranded = (args) => <Link {...args} />;
InlineBranded.args = {
  ...Inline.args,
  variant: 'branded',
};

export const InlineWithIcon = (args) => <Link block {...args} />;
InlineWithIcon.args = {
  ...Inline.args,
  icon: CogIcon,
};

export const Block = (args) => <Link {...args} />;
Block.args = {
  ...Inline.args,
  block: true,
  variant: undefined,
  children: 'Block link',
};

export const BlockBranded = (args) => <Link {...args} />;
BlockBranded.args = {
  ...Block.args,
  variant: 'branded',
};

export const BlockWithIcon = (args) => <Link block {...args} />;
BlockWithIcon.args = {
  ...Block.args,
  icon: CogIcon,
};
