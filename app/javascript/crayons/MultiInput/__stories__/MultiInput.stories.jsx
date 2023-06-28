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
      inputRegex: {
        description: 'A regular expression used to restrict the input',
      },
      validationRegex: {
        description: 'A regular expression used to validate the value of input',
      },
      labelText: {
        description: 'The label for the input',
      },
      showLabel: {
        description:
          'Should the label text be visible (it will always be available to assistive technology regardless)',
      },
    },
  },
};

export const Default = (args) => {
  return <MultiInput {...args} />;
};

Default.args = {
  placeholder: 'Add an email address...',
  inputRegex: /([a-zA-Z0-9@_.+-])/,
  validationRegex: /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/,
  labelText: 'Example multi input',
  showLabel: true,
};

Default.storyName = 'default';
