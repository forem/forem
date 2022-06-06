import { h } from 'preact';
import { MultiInput } from '../MultiInput';
import MultiInputDoc from './MultiInput.mdx';

export default {
  title: 'BETA/MultiInput',
  argTypes: {},
  parameters: {
    docs: {
      page: MultiInputDoc,
    },
  },
};

export const Default = () => {
  return <MultiInput />;
};

Default.story = {
  name: 'default',
};
