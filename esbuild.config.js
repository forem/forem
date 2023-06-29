/*eslint no-undef: "error"*/
/*eslint-env node*/

const glob = require('glob-all');
const esbuild = require('esbuild');
const railsEnv = process.env.RAILS_ENV || 'development';
const optimize = railsEnv !== 'development';

esbuild
  .build({
    entryPoints: glob.sync([
      'app/javascript/packs/**/*.*',
      'app/assets/javascripts/**/*.*',
      'app/javascript/application.js',
    ]),
    bundle: true,
    minify: optimize,
    sourcemap: true,
    // assetNames: '[name]-[hash].digested',
    // chunkNames: '[name]-[hash].digested',
    logLevel: 'info',
    // splitting: true,
    outdir: 'app/assets/builds',
    publicPath: 'assets',
    loader: { '.js': 'jsx', '.erb': 'file', '.toml': 'file', '.svg': 'file' },
    external: ['@crayons'],
  })
  .catch(() => process.exit(1));
