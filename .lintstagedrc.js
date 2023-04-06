// .lintstagedrc.js
module.exports = {
  '*.json': ['prettier --write'],
  '*.md': ['prettier --write --prose-wrap always'],
  '*.rake': ['bundle exec rubocop --autocorrect'],
  '*.scss': ['prettier --write'],
  '*.svg': ['svgo --pretty'],
  '*.{js,jsx}': [
    'prettier --write',
    'eslint --fix',
    'jest --findRelatedTests --passWithNoTests',
  ],
  './Gemfile': ['bundle exec rubocop --autocorrect'],
  'app/**/*.html.erb': ['bundle exec erblint --autocorrect'],
  'app/assets/config/manifest.js': [
    'prettier --write',
    'eslint --fix -c app/assets/javascripts/.eslintrc.js',
  ],
  'app/views/**/*.jbuilder': ['bundle exec rubocop --autocorrect'],
  // 'config/locales/*': () => 'bundle exec i18n-tasks normalize',
  'scripts/{release,stage_release}': ['bundle exec rubocop --autocorrect'],
  '{app,spec,config,lib}/**/*.rb': ['bundle exec rubocop --autocorrect'],
};
