const fs = require('fs');
const path = require('path');
const util = require('util');

const {
  GENERATED_STORIES_FOLDER,
  getStyleSheet,
  generateUtilityClassesDocumentation,
} = require('./documentation');

const folderExists = util.promisify(fs.exists);
const mkdir = util.promisify(fs.mkdir);
const stylesheetsDirectory = path.resolve(
  __dirname,
  '../../assets/stylesheets',
);

(async () => {
  console.log('Ensuring the auto-generated Storybook folder exists.');

  if (!(await folderExists(GENERATED_STORIES_FOLDER))) {
    console.log(
      'The auto-generated Storybook folder does not exist. Creating it.',
    );
    await mkdir(GENERATED_STORIES_FOLDER, { recursive: true });
  }

  const utilityClassesFilename = path.join(
    stylesheetsDirectory,
    'config/_generator.scss',
  );

  console.log(`Generating the style sheet for ${utilityClassesFilename}`);

  try {
    const styleSheet = await getStyleSheet(utilityClassesFilename);

    await generateUtilityClassesDocumentation(styleSheet);
  } catch (error) {
    throw new Error('Error generating the CSS utilty class Storybook stories');
  }
})();
