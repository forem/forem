#!/usr/bin/env node

/* eslint-env node */

const fs = require('fs');
const path = require('path');
const util = require('util');
const folderExists = util.promisify(fs.exists);
const mkdir = util.promisify(fs.mkdir);
const sass = require('sass');
const CSSOM = require('cssom');
const prettier = require('prettier');
const renderCss = util.promisify(sass.render);
const file = fs.promises;

const stylesheetsDirectory = path.resolve(
  __dirname,
  '../app/assets/stylesheets',
);
const GENERATED_STORIES_FOLDER = path.join(
  __dirname,
  '../app/javascript/generated_stories/__stories__',
);

/**
 * Generates a style sheet object for the given SASS/CSS file.
 *
 * @param {string} file The file to load as a style sheet.
 *
 * @returns {CSSStyleSheet} The stylesheet for the given file.
 */
async function getStyleSheet(file) {
  const { css: bytes } = await renderCss({
    file,
  });
  const utilityClassesContent = new TextDecoder('utf-8').decode(bytes);
  const styleSheet = CSSOM.parse(utilityClassesContent);

  return styleSheet;
}

/**
 * Groups CSS rules by CSS property.
 *
 * @param {CSSRule} rules A set of CSS rules
 *
 * @returns {object} A lookup whose keys are CSS properties
 * and the values are a lookup whose keys are CSS utility class names
 * and the values are the associated CSS rule.
 */
function groupCssRulesByCssProperty(rules) {
  const groupedRules = rules.reduce((acc, rule) => {
    if (rule.media) {
      return acc;
    }

    // Utility classes can modify more than one property, so we classify the CSS rule under
    // more than one CSS property potentially.
    // It means things will be repeated in Storybook, but it's all auto-generated, so no biggie.
    for (let i = 0; i < rule.style.length; i++) {
      const cssProperty = rule.style[i];

      acc[cssProperty] = acc[cssProperty] || {};
      acc[cssProperty][rule.selectorText] = rule;
    }

    return acc;
  }, {});

  return groupedRules;
}

/**
 * Generates the content for Storybook stories for all the CSS utility
 * classes associated to the given CSS property.
 *
 * @param {string} cssProperty A CSS property
 * @param {object} cssRules A lookup whose keys are CSS utility class
 * names and the values are CSS rules.action-space
 *
 * @returns {string} The content for Storybook stories for all the CSS
 * utility classes associated to the given CSS property
 */
function generateUtilityClassStories(cssProperty, cssRules) {
  const storybookStories = [
    `  // This is an auto-generated file. DO NOT EDIT
    import { h } from 'preact';
    import '../../crayons/storybook-utilities/designSystem.scss';

    export default {
      title: 'Utility-First Classes/${cssProperty}',
    };`,
  ];

  for (const [className, cssRule] of Object.entries(cssRules)) {
    const sanitizedCssClassName = className.replace(/[.-]/g, '_');
    const propertiesAndValues = [];

    for (let i = 0; i < cssRule.style.length; i++) {
      const styleProperty = cssRule.style[i];
      const value = cssRule.style[styleProperty];

      propertiesAndValues.push(`<li>
          <a
            href="https://developer.mozilla.org/en-US/docs/Web/CSS/${styleProperty}"
            target="_blank"
            rel="noopener noreferrer"
          >${styleProperty}</a> set to <code>${value}</code>
        </li>`);
    }

    storybookStories.push(`
    export const ${sanitizedCssClassName} = () => <div class="container">
      <p><code>${className}</code> utility class for the following CSS properties:</p>
      <ul>
        ${propertiesAndValues.join('')}
      </ul>
      <pre><code>{\`${prettier.format(cssRule.cssText, {
        parser: 'css',
      })}\`}</code></pre>
    </div>

    ${sanitizedCssClassName}.storyName = '${className.replace(/^\./, '')}';
    `);
  }

  return storybookStories.join('');
}

async function generateUtilityClassesDocumentation(
  styleSheet,
  fileWriter = file.writeFile,
) {
  if (!process.env.CI) {
    // eslint-disable-next-line no-console
    console.log('Grouping stylesheet rules by CSS property');
  }

  const rulesForStorybook = groupCssRulesByCssProperty(styleSheet.cssRules);

  for (const [cssProperty, cssRules] of Object.entries(rulesForStorybook)) {
    const storybookContent = generateUtilityClassStories(cssProperty, cssRules);

    if (!process.env.CI) {
      // eslint-disable-next-line no-console
      console.log(
        `Persisting Storybook stories for CSS utility classes related to the ${cssProperty} property.`,
      );
    }

    await fileWriter(
      path.join(
        GENERATED_STORIES_FOLDER,
        `${cssProperty}_utilityClasses.stories.jsx`,
      ),
      storybookContent,
    );
  }
}

async function generateDocumentation() {
  if (!process.env.CI) {
    // eslint-disable-next-line no-console
    console.log('Ensuring the auto-generated Storybook folder exists.');
  }

  if (!(await folderExists(GENERATED_STORIES_FOLDER))) {
    if (!process.env.CI) {
      // eslint-disable-next-line no-console
      console.log(
        'The auto-generated Storybook folder does not exist. Creating it.',
      );
    }

    await mkdir(GENERATED_STORIES_FOLDER, { recursive: true });
  }

  const utilityClassesFilename = path.join(
    stylesheetsDirectory,
    'config/_generator.scss',
  );

  if (!process.env.CI) {
    // eslint-disable-next-line no-console
    console.log(`Generating the style sheet for ${utilityClassesFilename}`);
  }

  try {
    const styleSheet = await getStyleSheet(utilityClassesFilename);

    await generateUtilityClassesDocumentation(styleSheet);
  } catch (error) {
    throw new Error('Error generating the CSS utility class Storybook stories');
  }
}

if (process.env.NODE_ENV !== 'test') {
  // we're running unit tests so do not run the function to generate docs.
  generateDocumentation();
}

/*
  These variables and functions are only used within this script, but they are being exported
  so that the core of the doc generation tool can be tested. Normally you would not export
  things deemed private.
*/
module.exports = {
  GENERATED_STORIES_FOLDER,
  getStyleSheet,
  generateUtilityClassesDocumentation,
};
