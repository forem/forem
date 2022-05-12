import { h } from 'preact';
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
  return <div>Multi Input</div>;
};

Default.story = {
  name: 'default',
};
