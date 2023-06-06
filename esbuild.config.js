/*eslint no-undef: "error"*/
/*eslint-env node*/

const glob = require('glob');
const esbuild = require('esbuild');

async () => {
  const context = await esbuild.context({
    entryPoints: glob.sync([
      'app/javascript/packs/**/*.js',
      'app/assets/javascripts/**/*.js',
    ]),
    bundle: true,
    sourcemap: true,
    assetNames: '[name]-[hash].digested',
    chunkNames: '[name]-[hash].digested',
    logLevel: 'info',
    splitting: true,
    outdir: 'app/assets/builds',
    loader: { '.erb': 'file', '.toml': 'file' },
    publicPath: 'assets',
  });

  await context.watch();
  await context.dispose();
};
