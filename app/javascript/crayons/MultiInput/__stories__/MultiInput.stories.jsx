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
      regex: {
        description: 'A regular expression used to validate the input',
      },
    },
  },
};

export const Default = (args) => {
  return <MultiInput {...args} />;
};

Default.args = {
  placeholder: 'Add an email address...',
  regex: /([a-zA-Z0-9@.])/,
};

Default.story = {
  name: 'default',
};
