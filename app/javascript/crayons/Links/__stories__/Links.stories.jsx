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
};

export const Inline = (args) => <Link {...args} />;
Inline.args = {
  href: '#',
  children: 'Inline link',
};

export const Block = (args) => <Link block {...args} />;
Block.args = {
  href: '#',
  rounded: false,
  children: 'Block link',
};

export const WithIcon = (args) => <Link block {...args} />;
WithIcon.args = {
  ...Block.args,
  icon: SampleIcon,
};
