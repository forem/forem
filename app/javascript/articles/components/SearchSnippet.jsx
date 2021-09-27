import { h } from 'preact';
import { articleSnippetResultPropTypes } from '../../common-prop-types';

export const SearchSnippet = ({ highlightText }) => {
  if (highlightText && highlightText.body_text.length > 0) {
    const hitHighlights = highlightText.body_text;
    let bodyTextSnippet = '';

    if (hitHighlights[0]) {
      const firstSnippetChar = hitHighlights[0];

      let startingEllipsis = '';
      if (firstSnippetChar.toLowerCase() !== firstSnippetChar.toUpperCase()) {
        startingEllipsis = '…';
      }
      bodyTextSnippet = `${startingEllipsis + hitHighlights.join('...')}…`;
    }

    if (bodyTextSnippet.length > 0) {
      return (
        <div className="crayons-story__snippet">
          <span>{bodyTextSnippet}</span>
        </div>
      );
    }
  }

  return null;
};

SearchSnippet.propTypes = {
  highlightText: articleSnippetResultPropTypes,
};

SearchSnippet.displayName = 'SearchSnippet';
