import { configure } from '@storybook/react';
import '../../assets/stylesheets/minimal.scss';
import '../../assets/javascripts/lib/xss';
import '../../assets/javascripts/utilities/timeAgo';
import './storybook.scss';

// automatically import all files ending in *.stories.js
const req = require.context('../', true, /.stories.jsx$/);
function loadStories() {
  req.keys().forEach(filename => req(filename));
}

configure(loadStories, module);
