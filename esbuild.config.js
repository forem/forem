const esbuild = require('esbuild')
const glob = require("glob");
const path = require("path");
const { aliasPath } = require ('esbuild-plugin-alias-path');
const aliasPlugin = require('esbuild-plugin-path-alias');

esbuild.build({
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.png': 'file',
    '.svg': 'file',
  },
  entryPoints: glob.sync("app/javascript/packs/*{.js, jsx}"),
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
}).catch(() => process.exit(1))


