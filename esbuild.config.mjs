import * as esbuild from 'esbuild'
import glob from 'glob'
import svgr from 'esbuild-plugin-svgr'

let ctx = {
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.png': 'file',
  },
  entryPoints: glob.sync("app/javascript/packs/*.*"),
  jsxFactory: 'h',
  jsxFragment: 'Fragment',
  bundle: true,
  minify: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  logLevel: 'info',
  define: {
    'global': 'window',
  },
  alias: {
    'react': 'preact/compat',
    'react-dom': 'preact/compat',
  },
  plugins: [svgr({
    jsxRuntime: 'classic-preact',
  })],
}

if (process.argv.includes('--watch')) {
  ctx = await esbuild.context(ctx)
  await ctx.watch()
} else {
  await esbuild.build(ctx)
}
