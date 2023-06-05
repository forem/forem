/*eslint no-undef: "error"*/
/*eslint-env node*/

const esbuild = require('esbuild');

async () => {
  const context = await esbuild.context({
    entryPoints: [
      'app/javascript/application.js',
      'app/assets/javascripts/initializePage.js',
    ],
    bundle: true,
    sourcemap: true,
    outdir: 'app/assets/builds',
    loader: { '.erb': 'file', '.toml': 'file' },
    publicPath: 'assets',
  });

  await context.watch();
  await context.dispose();
};

(' app/javascript/*.* --bundle --loader:.erb=file --loader:.toml=file --sourcemap --outdir=app/assets/builds --public-path=assets');
