import { h } from 'preact';
import { TagAutocompleteOption } from '../TagAutocompleteOption';

export default {
  component: TagAutocompleteOption,
  title: 'App Components/Article Form/TagAutocompleteOption',
  argTypes: {
    name: {
      control: 'text',
      description: 'The tag name, used for the title of the option',
    },
    backgroundColor: {
      control: 'color',
      description: 'An optional hex code to customise the color of the #',
    },
    shortSummary: {
      control: 'text',
      description:
        'An optional short summary of the tag, which will be curtailed at 2 lines',
    },
    badgeUrl: {
      control: 'text',
      description: 'An optional image src URL to display in the title',
    },
  },
};

export const Default = (args) => <TagAutocompleteOption {...args} />;
Default.args = {
  name: 'exampletagname',
  backgroundColor: '',
  shortSummary:
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent eget ultricies enim, quis finibus erat. Phasellus at nibh non libero sollicitudin accumsan eu nec velit. Cras maximus porta dui. Etiam aliquam in tellus sed vehicula. Morbi a sapien ut ante euismod imperdiet. Donec sodales ipsum ut ipsum luctus semper. ',
  badgeUrl: '/images/apple-icon.png',
};
