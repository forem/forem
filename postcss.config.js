/* globals module, require */
module.exports = {
  plugins: [
    require('postcss-import')({
      resolve: function(id, basedir) {
        if (id.startsWith('/assets/react-dates/')) {
          return require('path').resolve(process.cwd(), "node_modules/react-dates/lib/css/_datepicker.css");
        } else {
          return require('path').resolve(basedir, id);
        }
      }
    }),
    require('postcss-flexbugs-fixes'),
    require('postcss-preset-env')({
      autoprefixer: { flexbox: 'no-2009' },
      stage: 3,
    }),
  ],
};
