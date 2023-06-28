import { h } from 'preact';

export const Select = () => (
  <select name="sort" class="crayons-select" aria-label="Sort By">
    <option value="creation-desc">Recently Created</option>
    <option value="published-desc">Recently Published</option>
    <option value="views-desc">Most Views</option>
    <option value="reactions-desc">Most Reactions</option>
    <option value="comments-desc">Most Comments</option>
  </select>
);

export default {
  component: Select,
  title: 'Components/Form Elements/Select',
};

export const Default = () => {
  return <Select />;
};

Default.storyName = 'default';
