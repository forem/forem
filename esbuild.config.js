const esbuild = require('esbuild')
const glob = require("glob");
const path = require("path");

esbuild.build({
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.png': 'file',
    '.svg': 'file',
  },
  entryPoints: glob.sync("app/javascript/packs/*.js*"),
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  define: {
    'global': 'window',
  },
}).catch(() => process.exit(1))


