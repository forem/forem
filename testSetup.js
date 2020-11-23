/* eslint-env node */
import 'jest-axe/extend-expect';
import filterXss from './app/assets/javascripts/lib/xss';

global.filterXss = filterXss;
