import { h } from 'preact';
import { Link } from '..';
import SampleIcon from '../../../../assets/images/cog.svg';

export default {
  component: Link,
  title: 'BETA/Navigation/Links',
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
