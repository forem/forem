import { h } from 'preact';
import { articleSnippetResultPropTypes } from '../../src/components/common-prop-types';

export const SearchSnippet = ({ highlightText }) => {
  if (highlightText && highlightText.body_text) {
    let bodyTextSnippet = '';

    if (highlightText.body_text[0] && highlightText.body_text[0] !== '') {
      const firstSnippetChar = highlightText.body_text[0];

      let startingEllipsis = '';
      if (firstSnippetChar.toLowerCase() !== firstSnippetChar.toUpperCase()) {
        startingEllipsis = '…';
      }
      bodyTextSnippet = `${startingEllipsis +
        highlightText.body_text.join('...')}…`;
    }

    if (bodyTextSnippet.length > 0) {
      return (
        <div className="search-snippet">
          <span>{bodyTextSnippet}</span>
        </div>
      );
    }
  }

  return null;
};

SearchSnippet.propTypes = {
  // eslint-disable-next-line no-underscore-dangle
  highlightText: articleSnippetResultPropTypes.isRequired,
};

SearchSnippet.displayName = 'SearchSnippet';
