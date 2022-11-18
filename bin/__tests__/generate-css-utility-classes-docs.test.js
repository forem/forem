/* globals require beforeEach jest describe it expect */
const path = require('path');
const {
  generateUtilityClassesDocumentation,
  GENERATED_STORIES_FOLDER,
} = require('../generate-css-utility-classes-docs');

function createMockFileWriter() {
  const files = {};
  async function fileWriter(file, content) {
    files[file] = content;
  }

  return { files, fileWriter };
}

function getStorybookFilePath(cssProperty) {
  return path.join(
    GENERATED_STORIES_FOLDER,
    `${cssProperty}_utilityClasses.stories.jsx`,
  );
}

describe('generateUtilityClassesDocumentation', () => {
  beforeEach(() => {
    // eslint-disable-next-line no-console
    console.log = jest.fn();
  });

  it('should generate a Storybook story file', () => {
    const expected = `  // This is an auto-generated file. DO NOT EDIT
    import { h } from 'preact';
    import '../../crayons/storybook-utilities/designSystem.scss';

    export default {
      title: 'Utility-First Classes/color',
    };
    export const _color_some_utility_class = () => <div class="container">
      <p><code>.color-some-utility-class</code> utility class for the following CSS properties:</p>
      <ul>
        <li>
          <a
            href="https://developer.mozilla.org/en-US/docs/Web/CSS/color"
            target="_blank"
            rel="noopener noreferrer"
          >color</a> set to <code>red</code>
        </li>
      </ul>
      <pre><code>{\`.color-some-utility-class {
  color: red;
}
\`}</code></pre>
    </div>

    _color_some_utility_class.storyName = 'color-some-utility-class';
    `;
    const styleSheet = {
      cssRules: [
        {
          style: {
            0: 'color',
            length: 1,
            color: 'red',
          },
          selectorText: '.color-some-utility-class',
          cssText: '.color-some-utility-class{color: red;}',
        },
      ],
    };

    const { files, fileWriter } = createMockFileWriter();
    const filePath = getStorybookFilePath('color');

    generateUtilityClassesDocumentation(styleSheet, fileWriter);

    expect(files[filePath]).toEqual(expected);
  });

  it('should generate a Storybook story file when a utility class has more than one property set', () => {
    const expected = `  // This is an auto-generated file. DO NOT EDIT
    import { h } from 'preact';
    import '../../crayons/storybook-utilities/designSystem.scss';

    export default {
      title: 'Utility-First Classes/color',
    };
    export const _color_some_utility_class = () => <div class="container">
      <p><code>.color-some-utility-class</code> utility class for the following CSS properties:</p>
      <ul>
        <li>
          <a
            href="https://developer.mozilla.org/en-US/docs/Web/CSS/color"
            target="_blank"
            rel="noopener noreferrer"
          >color</a> set to <code>red</code>
        </li><li>
          <a
            href="https://developer.mozilla.org/en-US/docs/Web/CSS/opacity"
            target="_blank"
            rel="noopener noreferrer"
          >opacity</a> set to <code>0.5</code>
        </li>
      </ul>
      <pre><code>{\`.color-some-utility-class {
  color: red;
  opacity: 0.5;
}
\`}</code></pre>
    </div>

    _color_some_utility_class.storyName = 'color-some-utility-class';
    `;
    const styleSheet = {
      cssRules: [
        {
          style: {
            0: 'color',
            1: 'opacity',
            length: 2,
            color: 'red',
            opacity: '0.5',
          },
          selectorText: '.color-some-utility-class',
          cssText: '.color-some-utility-class{color: red;opacity: 0.5}',
        },
      ],
    };

    const { files, fileWriter } = createMockFileWriter();
    const filePath = getStorybookFilePath('color');

    generateUtilityClassesDocumentation(styleSheet, fileWriter);

    expect(files[filePath]).toEqual(expected);
  });

  it('should generate a Storybook story file with CSS utility classes', () => {
    const expected = `  // This is an auto-generated file. DO NOT EDIT
    import { h } from 'preact';
    import '../../crayons/storybook-utilities/designSystem.scss';

    export default {
      title: 'Utility-First Classes/color',
    };
    export const _color_some_utility_class = () => <div class="container">
      <p><code>.color-some-utility-class</code> utility class for the following CSS properties:</p>
      <ul>
        <li>
          <a
            href="https://developer.mozilla.org/en-US/docs/Web/CSS/color"
            target="_blank"
            rel="noopener noreferrer"
          >color</a> set to <code>red</code>
        </li>
      </ul>
      <pre><code>{\`.color-some-utility-class {
  color: red;
}
\`}</code></pre>
    </div>

    _color_some_utility_class.storyName = 'color-some-utility-class';
    `;
    const styleSheet = {
      cssRules: [
        {
          style: {
            0: 'color',
            length: 1,
            color: 'red',
          },
          selectorText: '.color-some-utility-class',
          cssText: '.color-some-utility-class{color: red;}',
        },
      ],
    };

    const { files, fileWriter } = createMockFileWriter();
    const filePath = getStorybookFilePath('color');

    generateUtilityClassesDocumentation(styleSheet, fileWriter);

    expect(files[filePath]).toEqual(expected);
  });

  it('should generate a Storybook story file for only non-@media CSS rules', () => {
    const expected = `  // This is an auto-generated file. DO NOT EDIT
    import { h } from 'preact';
    import '../../crayons/storybook-utilities/designSystem.scss';

    export default {
      title: 'Utility-First Classes/color',
    };
    export const _color_some_utility_class = () => <div class="container">
      <p><code>.color-some-utility-class</code> utility class for the following CSS properties:</p>
      <ul>
        <li>
          <a
            href="https://developer.mozilla.org/en-US/docs/Web/CSS/color"
            target="_blank"
            rel="noopener noreferrer"
          >color</a> set to <code>red</code>
        </li>
      </ul>
      <pre><code>{\`.color-some-utility-class {
  color: red;
}
\`}</code></pre>
    </div>

    _color_some_utility_class.storyName = 'color-some-utility-class';
    `;
    const styleSheet = {
      cssRules: [
        {
          style: {
            0: 'color',
            length: 1,
            color: 'red',
          },
          selectorText: '.color-some-utility-class',
          cssText: '.color-some-utility-class{color: red;}',
        },
        {
          style: {
            0: 'width',
            length: 1,
          },
          media: 'some-media-rule',
        },
      ],
    };

    const { files, fileWriter } = createMockFileWriter();

    generateUtilityClassesDocumentation(styleSheet, fileWriter);
    const filePath = getStorybookFilePath('color');
    expect(files[filePath]).toEqual(expected);
  });
});
