import * as esbuild from 'esbuild'
import glob from 'glob'
import path from 'path'

let ctx = {
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
  logLevel: 'info',
  define: {
    'global': 'window',
  },
}

if (process.argv.includes('--watch')) {
  ctx = await esbuild.context(ctx)
  await ctx.watch()
} else {
  // build normally
  await esbuild.build(ctx)
}


