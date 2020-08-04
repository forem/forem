const path = require('path');
const util = require('util');
const fs = require('fs');
const sass = require('node-sass');
const CSSOM = require('cssom');
const renderCss = util.promisify(sass.render);
const file = fs.promises;
const stylesheetsDirectory = path.resolve(
  __dirname,
  '../../assets/stylesheets',
);

// TODO: Clean this up once things are working.

async function generateDocumentation(themeFiles) {
  try {
    const storybookContent = [];
    storybookContent.push(`import { h } from 'preact';

  import '../../crayons/storybook-utilities/designSystem.scss';

  export default {
    title: '2_Base/Color',
  };`);

    for (const { theme, themeFile } of themeFiles) {
      const { css: bytes } = await renderCss({
        file: themeFile,
      });
      const colorFileContents = new TextDecoder('utf-8').decode(bytes);

      storybookContent.push(`
  export const ${theme}ThemeColors = () => <div class="container">
    <pre><code>{\`${colorFileContents}\`}</code></pre>
  </div>

  ${theme}ThemeColors.story = { name: '${theme} theme colors' };
  `);
    }

    await file.writeFile(
      path.join(generatedStoriesFolder, `colors.stories.jsx`),
      storybookContent.join(''),
    );
  } catch (error) {
    console.error(error);
  }
}

async function generateUtilityClassesDocumentation(utilityClassesFilename) {
  try {
    const { css: bytes } = await renderCss({
      file: utilityClassesFilename,
    });
    const utilityClassesContent = new TextDecoder('utf-8').decode(bytes);
    const stylesheet = CSSOM.parse(utilityClassesContent);
    const rulesForStorybook = stylesheet.cssRules.reduce((acc, rule) => {
      if (rule.media) {
        return acc;
      }

      const cssProperty = rule.style['0'];

      acc[cssProperty] = acc[cssProperty] || {};
      acc[cssProperty][rule.selectorText] = rule;

      return acc;
    }, {});

    for (const [cssProperty, cssRules] of Object.entries(rulesForStorybook)) {
      const storybookContent = [];
      storybookContent.push(`import { h } from 'preact';

  import '../../crayons/storybook-utilities/designSystem.scss';

  export default {
    title: '5_CSS Utility classes/${cssProperty}',
  };`);

      for (const [className, cssRule] of Object.entries(cssRules)) {
        const sanitizedCssClassName = className.replace(/[.-]/g, '_');
        const value = cssRule.style[cssRule.style['0']];
        const isImportant =
          cssRule.style._importants[cssRule.style['0']] === 'important';
        storybookContent.push(`
  export const ${sanitizedCssClassName} = () => <div class="container">
    <p>CSS utility class for the <strong>${cssProperty}</strong> CSS property to set it's value to <strong>${value}</strong>. ${
          isImportant
            ? 'Note that <strong>!important</strong> is being used to override pre-design system CSS.'
            : ''
        }</p>
    <pre><code>{\`${cssRule.cssText}\`}</code></pre>
  </div>

  ${sanitizedCssClassName}.story = { name: '${className}' };
  `);
      }

      await file.writeFile(
        path.join(
          generatedStoriesFolder,
          `${cssProperty}_utilityClasses.stories.jsx`,
        ),
        storybookContent.join(''),
      );
    }
  } catch (error) {
    console.error(error);
  }
}

const generatedStoriesFolder = path.join(
  __dirname,
  '../../javascript/generated_stories/__stories__',
);

if (!fs.existsSync(generatedStoriesFolder)) {
  fs.mkdirSync(generatedStoriesFolder, { recursive: true });
}

fs.readdir(
  path.join(stylesheetsDirectory, 'themes'),
  async (err, themeFiles) => {
    if (err) {
      throw new Error(
        'Unable to read theme files. Ensure that the path to theme files is correct.',
      );
    }

    const themes = [
      {
        theme: 'default',
        themeFile: path.join(stylesheetsDirectory, 'config/_colors.scss'),
      },
    ];
    const additionalThemes = themeFiles.map((filename) => {
      return {
        theme: filename.replace('.scss', ''),
        themeFile: path.join(stylesheetsDirectory, 'themes', filename),
      };
    });

    await generateDocumentation(themes.concat(additionalThemes));
    await generateUtilityClassesDocumentation(
      path.join(stylesheetsDirectory, 'config/_generator.scss'),
    );
  },
);
