/*eslint no-undef: "error"*/
/*eslint-env node*/

const glob = require('glob');
const esbuild = require('esbuild');

esbuild
  .build({
    entryPoints: glob.sync('app/javascript/packs/initializers/*.js'),
    bundle: true,
    sourcemap: true,
    // assetNames: '[name]-[hash].digested',
    // chunkNames: '[name]-[hash].digested',
    // logLevel: 'info',
    // splitting: true,
    outdir: 'app/assets/builds',
    loader: { '.erb': 'file', '.toml': 'file' },
    // publicPath: 'assets',
  })
  .catch(() => process.exit(1));
