import * as esbuild from 'esbuild'
import glob from 'glob'
import svgr from 'esbuild-plugin-svgr'

let ctx = {
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.png': 'file',
  },
  entryPoints: glob.sync("app/javascript/packs/**/*.js*"),
  jsxFactory: 'h',
  jsxFragment: 'Fragment',
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  logLevel: 'info',
  define: {
    'global': 'window',
  },
  plugins: [svgr({
    jsxRuntime: 'classic-preact',
  })],
}

if (process.argv.includes('--watch')) {
  ctx = await esbuild.context(ctx)
  await ctx.watch()
} else {
  // build normally
  await esbuild.build(ctx)
}


