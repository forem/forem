// .lintstagedrc.js
module.exports = {
  'app/assets/config/manifest.js': [
    'prettier --write',
    'eslint --fix -c app/assets/javascripts/.eslintrc.js',
  ],
  '*.{js,jsx}': ['prettier --write', 'eslint --fix', 'jest --findRelatedTests'],
  '{app,spec,config,lib}/**/*.rb': [
    'bundle exec rubocop --require rubocop-rspec --auto-correct --enable-pending-cops',
  ],
  'scripts/{release,stage_release}': [
    'bundle exec rubocop --require rubocop-rspec --auto-correct --enable-pending-cops',
  ],
  'app/views/**/*.jbuilder': [
    'bundle exec rubocop --require rubocop-rspec --auto-correct --enable-pending-cops',
  ],
  './Gemfile': [
    'bundle exec rubocop --require rubocop-rspec --auto-correct --enable-pending-cops',
  ],
  '*.rake': [
    'bundle exec rubocop --require rubocop-rspec --auto-correct --enable-pending-cops',
  ],
  'config/locales/*': () => 'bundle exec i18n-tasks normalize',
  'app/**/*.html.erb': ['bundle exec erblint --autocorrect'],
  '*.json': ['prettier --write'],
  '*.scss': ['prettier --write'],
  '*.md': ['prettier --write --prose-wrap always'],
  '*.svg': ['svgo --pretty'],
};
