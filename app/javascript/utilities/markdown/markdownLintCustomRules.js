/**
 * Custom markdown lint rule that detects if a user has uploaded an image, but not changed the default alt text
 */
export const noDefaultAltTextRule = {
  names: ['no-default-alt-text'],
  description: 'Images should not have the default alt text',
  tags: ['images'],
  function: (params, onError) => {
    params.tokens
      .filter((token) => token.type === 'inline')
      .forEach((inlineToken) => {
        inlineToken.children.forEach((contentChild) => {
          if (
            contentChild.type === 'image' &&
            contentChild.line.toLowerCase().includes('![alt text]')
          ) {
            onError({
              lineNumber: inlineToken.lineNumber,
              detail: `Alt text not replaced with description`,
              context: `Consider replacing the'alt text' in square brackets at ${contentChild.line} with a description of the image`,
            });
          }
        });
      });
  },
};

/**
 * A custom rule that mirrors the default "no-alt-text" rule, but with a more helpful error message
 */
export const noEmptyAltTextRule = {
  names: ['no-empty-alt-text'],
  description: 'Images should not have empty alt text',
  tags: ['images'],
  function: (params, onError) => {
    params.tokens
      .filter((token) => token.type === 'inline')
      .forEach((inlineToken) => {
        inlineToken.children.forEach((contentChild) => {
          if (
            contentChild.type === 'image' &&
            contentChild.line.toLowerCase().includes('![]')
          ) {
            onError({
              lineNumber: inlineToken.lineNumber,
              detail: 'Empty alt text',
              context: `Consider adding an image description in the square brackets at ${contentChild.line}`,
            });
          }
        });
      });
  },
};

/**
 * Custom markdown lint rule that detects if a level one heading has been used in a post
 */
export const noLevelOneHeadingsRule = {
  names: ['no-level-one-heading'],
  description: 'Heading level one should not be used in posts',
  tags: ['headings'],
  function: (params, onError) => {
    const levelOneHeadings = [];
    params.tokens.filter((token, index) => {
      const isHeadingOneStart =
        token.type === 'heading_open' && token.tag === 'h1';
      if (isHeadingOneStart) {
        // The next token is the actual content of the heading
        levelOneHeadings.push(params.tokens[index + 1]);
      }
    });

    levelOneHeadings.forEach((heading) => {
      onError({
        lineNumber: heading.lineNumber,
        context: `Consider changing "${heading.line}" to a level two heading by using ##`,
        detail: 'Level one heading used in post',
      });
    });
  },
};

/**
 * A custom rule that mirrors the default "heading-increment" rule, but with a more helpful error message
 */
export const headingIncrement = {
  names: ['custom-heading-increment'],
  description: 'Heading levels should only increment by one level at a time',
  tags: ['headings', 'headers'],
  function: (params, onError) => {
    let prevLevel = 0;

    const headings = params.tokens.filter(
      (token) => token.type === 'heading_open',
    );
    headings.forEach((heading) => {
      const level = Number.parseInt(heading.tag.slice(1), 10);
      if (prevLevel && level > prevLevel) {
        // Heading level has increased
        const suggestedHeadingLevel = prevLevel + 1;

        if (suggestedHeadingLevel !== level) {
          const suggestedHeadingStart = Array(suggestedHeadingLevel)
            .fill('#')
            .join('');

          onError({
            lineNumber: heading.lineNumber,
            context: `Consider changing the heading "${heading.line}" to a level ${suggestedHeadingLevel} heading by using ${suggestedHeadingStart}`,
          });
        }
      }
      prevLevel = level;
    });
  },
};
