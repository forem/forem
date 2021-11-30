import { h } from 'preact';
import { Icon } from '..';
import IconsDoc from './Icons.mdx';
import CogIcon from '@images/twitter.svg';

export default {
  component: Icon,
  title: 'BETA/Icons',
  parameters: {
    docs: {
      page: IconsDoc,
    },
  },
  argTypes: {
    native: {
      description:
        'Whether or not icon should maintain its original color. By default (`false`) icon will inherit color from parent container. Most of our icons actually come "unstyled" - which means they are meant to inherit color from parent. Using native colors should be an exception for e.g. branded icons that come with their own specific color (some logos like Twitter, Facebook, etc.) or multicolor icons.',
      table: {
        defaultValue: { summary: false },
      },
    },
  },
};

export const Default = (args) => <Icon src={CogIcon} {...args} />;
Default.args = {
  native: false,
};

export const NativeColors = (args) => <Icon src={CogIcon} {...args} />;
NativeColors.args = {
  native: true,
};
