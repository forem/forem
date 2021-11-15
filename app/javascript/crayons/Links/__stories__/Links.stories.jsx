import { h } from 'preact';
import { Link } from '..';
import LinksDoc from './Links.mdx';
import SampleIcon from '@img/cog.svg';

export default {
  component: Link,
  title: 'BETA/Navigation/Links',
  parameters: {
    docs: {
      page: LinksDoc,
    },
  },
  argTypes: {
    style: {
      control: {
        type: 'select',
        options: ['default', 'branded'],
      },
      description: 'There are two available styles to pick from: _default_ and _branded_. The primary difference is color: _default_ uses grey color and _branded_ uses accent color.',
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
  },
};

export const Inline = (args) => <Link {...args} />;
Inline.args = {
  style: 'branded',
  block: false,
  rounded: false,
  children: 'Inline link',
};

export const Block = (args) => <Link {...args} />;
Block.args = {
  ...Inline.args,
  block: true,
  style: 'default',
  children: 'Block link',
};

export const WithIcon = (args) => <Link block {...args} />;
WithIcon.args = {
  ...Block.args,
  icon: SampleIcon,
};
