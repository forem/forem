// .lintstagedrc.js
module.exports = {
  '*.json': ['prettier --write'],
  '*.md': ['prettier --write --prose-wrap always'],
  '*.rake': [
    'bundle exec rubocop --require rubocop-rspec --autocorrect --enable-pending-cops',
  ],
  '*.scss': ['prettier --write'],
  '*.svg': ['svgo --pretty'],
  '*.{js,jsx}': [
    'prettier --write',
    'eslint --fix',
    'jest --findRelatedTests --passWithNoTests',
  ],
  './Gemfile': [
    'bundle exec rubocop --require rubocop-rspec --autocorrect --enable-pending-cops',
  ],
  'app/**/*.html.erb': ['bundle exec erblint --autocorrect'],
  'app/assets/config/manifest.js': [
    'prettier --write',
    'eslint --fix -c app/assets/javascripts/.eslintrc.js',
  ],
  'app/views/**/*.jbuilder': [
    'bundle exec rubocop --require rubocop-rspec --autocorrect --enable-pending-cops',
  ],
  // 'config/locales/*': () => 'bundle exec i18n-tasks normalize',
  'scripts/{release,stage_release}': [
    'bundle exec rubocop --require rubocop-rspec --autocorrect --enable-pending-cops',
  ],
  '{app,spec,config,lib}/**/*.rb': [
    'bundle exec rubocop --require rubocop-rspec --autocorrect --enable-pending-cops',
  ],
};
