import { h } from 'preact';
import { deep } from 'preact-render-spy';
import ClassifiedFiltersTags from '../components/ClassifiedFiltersTags';

describe('<ClassifiedFilterTags />', () => {
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

  const getTags = () => [firstTag, secondTag, thirdTag];

  const getProps = () => ({
    message: 'Some message',
    onKeyUp: () => {
      return 'onKeyUp';
    },
    onClearQuery: () => {
      return 'onClearQuery';
    },
    onRemoveTag: () => {
      return 'onRemoveTag';
    },
    onKeyPress: () => {
      return 'onKeyPress';
    },
    query: 'some-string&this=1',
    tags: getTags(),
  });

  const renderClassifiedFilterTags = (props = getProps()) =>
    deep(<ClassifiedFiltersTags {...props} />);

  describe('Should render a search field', () => {
    const context = renderClassifiedFilterTags();
    const searchField = context.find('#listings-search');

    it('Should have "search" as placeholder', () => {
      expect(searchField.attr('placeholder')).toBe('search');
    });

    it(`Should have "${getProps().message}" as default value`, () => {
      expect(searchField.attr('defaultValue')).toBe(getProps().message);
    });

    it('Should have auto-complete as off', () => {
      expect(searchField.attr('autoComplete')).toBe('off');
    });
  });

  describe('<ClearQueryButton />', () => {
    const context = renderClassifiedFilterTags();

    it('Should render the clear query button', () => {
      expect(context.find('#clear-query-button').exists()).toBe(true);
    });

    it('Should not render the clear query button', () => {
      const propsWithoutQuery = { ...getProps(), query: '' };
      const contextWithAnotherProps = renderClassifiedFilterTags(
        propsWithoutQuery,
      );

      expect(contextWithAnotherProps.find('#clearQueryButton').exists()).toBe(
        false,
      );
    });
  });

  it('Should render the selected Tags', () => {
    const context = renderClassifiedFilterTags();
    getTags().forEach((tag) => {
      const selectedTag = context.find(`#selected-tag-${tag.id}`);

      expect(selectedTag.text()).toBe('×');
    });
  });
});
