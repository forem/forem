import { h } from 'preact';
import { MentionAutocomplete } from '../MentionAutocomplete';

export default {
  title: 'Components/MentionAutocomplete',
};

export const Default = () => (
  <div>
    <MentionAutocomplete onSelect={() => console.log('selected')} />
  </div>
);

Default.story = {
  name: 'default',
};
