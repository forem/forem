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
    argTypes: {
      placeholder: {
        description:
          'Placeholder text, shown when no selections have been made yet',
      },
    },
  },
};

export const Default = (args) => {
  return <MultiInput {...args} />;
};

Default.args = {
  placeholder: 'Add an email address...',
};

Default.story = {
  name: 'default',
};
