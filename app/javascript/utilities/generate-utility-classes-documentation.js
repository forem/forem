const fs = require('fs');
const path = require('path');
const util = require('util');

const {
  GENERATED_STORIES_FOLDER,
  generateUtilityClassesDocumentation,
} = require('./documentation');

const folderExists = util.promisify(fs.exists);
const mkdir = util.promisify(fs.mkdir);
const stylesheetsDirectory = path.resolve(
  __dirname,
  '../../assets/stylesheets',
);

(async () => {
  // ensure the auto-generated Storybook folder exists.
  if (!(await folderExists(GENERATED_STORIES_FOLDER))) {
    await mkdir(GENERATED_STORIES_FOLDER, { recursive: true });
  }

  try {
    await generateUtilityClassesDocumentation(
      path.join(stylesheetsDirectory, 'config/_generator.scss'),
    );
  } catch (error) {
    throw new Error('Error generating the CSS utilty class Storybook stories');
  }
})();
