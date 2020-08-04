const path = require('path');
const util = require('util');
const fs = require('fs');
const sass = require('node-sass');
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
    const storybookContent = [];
    storybookContent.push(`import { h } from 'preact';

  import '../../crayons/storybook-utilities/designSystem.scss';

  export default {
    title: '2_Base',
  };`);

    const { css: bytes } = await renderCss({
      file: utilityClassesFilename,
    });
    const utilityClassesContent = new TextDecoder('utf-8').decode(bytes);

    storybookContent.push(`
  export const UtilityClasses = () => <div class="container">
    <pre><code>{\`${utilityClassesContent}\`}</code></pre>
  </div>

  UtilityClasses.story = { name: 'Utility classes' };
  `);

    await file.writeFile(
      path.join(generatedStoriesFolder, `utilityClasses.stories.jsx`),
      storybookContent.join(''),
    );
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
