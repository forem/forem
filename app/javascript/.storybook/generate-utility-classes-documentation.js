const path = require('path');
const fs = require('fs');
const file = fs.promises;
const stylesheetsDirectory = path.resolve(
  __dirname,
  '../../assets/stylesheets',
);

const themeFiles = [
  { theme: 'default', themeFile: 'config/_colors.scss' },
  { theme: 'hacker', themeFile: 'themes/hacker.scss' },
  { theme: 'minimal', themeFile: 'themes/minimal.scss' },
  { theme: 'night', themeFile: 'themes/night.scss' },
  { theme: 'pink', themeFile: 'themes/pink.scss' },
];

(async () => {
  const generatedStoriesFolder = path.join(
    __dirname,
    '../../javascript/generated_stories/__stories__',
  );

  if (!fs.existsSync(generatedStoriesFolder)) {
    fs.mkdirSync(generatedStoriesFolder, { recursive: true });
  }

  try {
    const storybookContent = [];
    storybookContent.push(`import { h } from 'preact';

  import '../../crayons/storybook-utilities/designSystem.scss';

  export default {
    title: '2_Base/Color',
  };`);

    for (const { theme, themeFile } of themeFiles) {
      const colorFile = path.join(stylesheetsDirectory, themeFile);
      const colorFileContents = await file.readFile(colorFile);

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
})();
