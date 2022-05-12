import { h } from 'preact';
import { MultiInput } from '../MultiInput';
import MultiInputDoc from './MultiInput.mdx';

export default {
  title: 'App Components/MultiInput',
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
