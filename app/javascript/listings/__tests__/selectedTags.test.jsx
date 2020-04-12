import { h } from 'preact';
import { deep } from 'preact-render-spy';
import SelectedTags from '../elements/selectedTags';

const firstTag = {
  id: 1,
  tag: 'clojure',
};
const secondTag = {
  id: 2,
  tag: 'java',
};
const thirdTag = {
  id: 3,
  tag: 'dotnet',
};

const tags = [firstTag, secondTag, thirdTag];
const defaultProps = {
  tags,
  onClick: () => {
    return 'onClick';
  },
  onKeyPress: () => {
    return 'onKeyPress';
  },
};

describe('<SelectedTags />', () => {
  const renderSelectedTags = () => deep(<SelectedTags {...defaultProps} />);

  it('Should render all the tags', () => {
    const context = renderSelectedTags();
    tags.forEach((tag) => {
      const selectedTag = context.find(`#selected-tag-${tag.id}`);

      expect(selectedTag.text()).toBe('×');
    });
  });
});
