import fs from 'fs'
import path from 'path'
import * as esbuild from 'esbuild'
import glob from 'glob'
import svgr from 'esbuild-plugin-svgr'
import { stimulusPlugin } from 'esbuild-plugin-stimulus'

const CRAYONS_DIRECT_EXPORT_MAP = {
  Button: 'app/javascript/crayons/Button/Button.jsx',
  ButtonNew: 'app/javascript/crayons/Buttons/Button.jsx',
  Buttons: 'app/javascript/crayons/Buttons/Button.jsx',
  Link: 'app/javascript/crayons/Links/Link.jsx',
  Links: 'app/javascript/crayons/Links/Link.jsx',
  CTA: 'app/javascript/crayons/CTAs/CTA.jsx',
  CTAs: 'app/javascript/crayons/CTAs/CTA.jsx',
  Pill: 'app/javascript/crayons/Pills/Pill.jsx',
  ButtonGroup: 'app/javascript/crayons/ButtonGroup/ButtonGroup.jsx',
  Dropdown: 'app/javascript/crayons/Dropdown/Dropdown.jsx',
  DropdownTrigger: 'app/javascript/crayons/Dropdown/DropdownTrigger.jsx',
  FormField: 'app/javascript/crayons/formElements/FormField/FormField.jsx',
  RadioButton: 'app/javascript/crayons/formElements/RadioButton/RadioButton.jsx',
  ColorPicker: 'app/javascript/crayons/formElements/ColorPicker/ColorPicker.jsx',
  ColorPopover: 'app/javascript/crayons/formElements/ColorPicker/ColorPicker.jsx',
  Toggle: 'app/javascript/crayons/formElements/Toggles/Toggle.jsx',
  DateRangePicker: 'app/javascript/crayons/formElements/DateRangePicker/DateRangePicker.jsx',
  ALL_PRESET_RANGES: 'app/javascript/crayons/formElements/DateRangePicker/dateRangeUtils.js',
  Icon: 'app/javascript/crayons/Icons/Icon.jsx',
  Icons: 'app/javascript/crayons/Icons/Icon.jsx',
  Modal: 'app/javascript/crayons/Modal/Modal.jsx',
  Spinner: 'app/javascript/crayons/Spinner/Spinner.jsx',
  MobileDrawer: 'app/javascript/crayons/MobileDrawer/MobileDrawer.jsx',
  MarkdownToolbar: 'app/javascript/crayons/MarkdownToolbar/MarkdownToolbar.jsx',
  TOOLBAR_TYPES: 'app/javascript/crayons/MarkdownToolbar/MarkdownToolbar.jsx',
  MultiSelectAutocomplete: 'app/javascript/crayons/MultiSelectAutocomplete/MultiSelectAutocomplete.jsx',
  FetchError: 'app/javascript/crayons/MultiSelectAutocomplete/MultiSelectAutocomplete.jsx',
  MultiInput: 'app/javascript/crayons/MultiInput/MultiInput.jsx',
  DELIMITERS: 'app/javascript/crayons/MultiInput/MultiInput.jsx',
  AutocompleteTriggerTextArea: 'app/javascript/crayons/AutocompleteTriggerTextArea/AutocompleteTriggerTextArea.jsx',
}

function rewriteCrayonsBarrelImports(source, filePath) {
  return source.replace(
    /import\s*\{([^}]+)\}\s*from\s*['"]@crayons(?:\/formElements)?['"]\s*;?/g,
    (fullMatch, specifiers) => {
      const items = specifiers
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean)
      const groupedByTarget = new Map()

      for (const item of items) {
        const [importedName] = item.split(/\s+as\s+/).map((part) => part.trim())
        const targetFile = CRAYONS_DIRECT_EXPORT_MAP[importedName]
        if (!targetFile) {
          return fullMatch
        }
        const resolvedTarget = path.resolve(targetFile)
        if (!groupedByTarget.has(resolvedTarget)) {
          groupedByTarget.set(resolvedTarget, [])
        }
        groupedByTarget.get(resolvedTarget).push(item)
      }

      return Array.from(groupedByTarget.entries())
        .map(([resolvedTarget, specs]) => {
          let relativeImport = path
            .relative(path.dirname(filePath), resolvedTarget)
            .replace(/\\/g, '/')
          if (!relativeImport.startsWith('.')) {
            relativeImport = `./${relativeImport}`
          }
          return `import { ${specs.join(', ')} } from '${relativeImport}';`
        })
        .join('\n')
    },
  ).replace(
    /import\s*\{\s*addSnackbarItem\s*\}\s*from\s*['"]([^'"]*\/Snackbar)['"]\s*;?/g,
    (_fullMatch, snackbarPath) =>
      `import { addSnackbarItem } from '${snackbarPath}/addSnackbarItem';`,
  )
}

function stripBalancedPropTypes(source) {
  const propTypesStartRegex = /^[ \t]*[A-Za-z0-9_$]+\.propTypes\s*=\s*\{/gm
  let result = ''
  let lastIndex = 0
  let match

  while ((match = propTypesStartRegex.exec(source)) !== null) {
    const startIdx = match.index
    const openBraceIdx = startIdx + match[0].length - 1
    let depth = 1
    let cursor = openBraceIdx + 1

    while (cursor < source.length && depth > 0) {
      const ch = source[cursor]
      if (ch === '{') {
        depth += 1
      } else if (ch === '}') {
        depth -= 1
      }
      cursor += 1
    }

    if (depth === 0) {
      while (cursor < source.length && (source[cursor] === ' ' || source[cursor] === '\t')) {
        cursor += 1
      }
      if (source[cursor] === ';') {
        cursor += 1
      }
      result += source.slice(lastIndex, startIdx)
      lastIndex = cursor
      propTypesStartRegex.lastIndex = cursor
    }
  }

  result += source.slice(lastIndex)
  return result
}

function stripProductionPropTypes(source) {
  let result = stripBalancedPropTypes(source)
    .replace(
      /^[ \t]*[A-Za-z0-9_$]+\.propTypes\s*=\s*[A-Za-z0-9_$.]+;?[ \t]*$/gm,
      '',
    )
    .replace(
      /^[ \t]*[A-Za-z0-9_$]+\.displayName\s*=\s*['"`][^'"`]*['"`];?[ \t]*$/gm,
      '',
    )

  const withoutPropTypesImport = result.replace(
    /^[ \t]*import\s+PropTypes\s+from\s+['"]prop-types['"]\s*;?[ \t]*$/gm,
    '',
  )
  if (!/\bPropTypes\b/.test(withoutPropTypesImport)) {
    result = withoutPropTypesImport.replace(
      /^[ \t]*import\s*\{([^}]+)\}\s*from\s*['"][^'"]*common-prop-types[^'"]*['"]\s*;?[ \t]*$/gm,
      (fullImport, specifiers) => {
        const remainingCode = withoutPropTypesImport.replace(fullImport, '')
        const importedNames = specifiers
          .split(',')
          .map((s) => s.trim().split(/\s+as\s+/).pop().trim())
          .filter(Boolean)
        const stillUsed = importedNames.some((name) =>
          new RegExp(`\\b${name}\\b`).test(remainingCode),
        )
        return stillUsed ? fullImport : ''
      },
    )
  }

  return result
}

function treeShakePlugin() {
  return {
    name: 'forem-tree-shake',
    setup(build) {
      build.onLoad(
        { filter: /app[\\/]javascript[\\/].*\.(js|jsx)$/ },
        async (args) => {
          const original = await fs.promises.readFile(args.path, 'utf8')
          const transformed = stripProductionPropTypes(
            rewriteCrayonsBarrelImports(original, args.path),
          )
          return {
            contents: transformed,
            loader: 'jsx',
          }
        },
      )
    },
  }
}

let ctx = {
  loader: {
    '.js': 'jsx',
    '.jsx': 'jsx',
    '.png': 'file',
  },
  target: ['es2019'],
  entryPoints: glob.sync("app/javascript/packs/**/*.*", { ignore: ["**/*.test.*", "**/__tests__/**"] }),
  jsxFactory: 'h',
  jsxFragment: 'Fragment',
  bundle: true,
  minify: true,
  sourcemap: false,
  outdir: 'app/assets/builds',
  logLevel: 'info',
  define: {
    'global': 'window',
    'process.env.NODE_ENV': '"production"',
  },
  alias: {
    'react': 'preact/compat',
    'react-dom': 'preact/compat',
  },
  plugins: [
    treeShakePlugin(),
    svgr({jsxRuntime: 'classic-preact' }),
    stimulusPlugin(),
  ],
}

if (process.argv.includes('--watch')) {
  ctx = await esbuild.context(ctx)
  await ctx.watch()
} else {
  await esbuild.build(ctx)
}
