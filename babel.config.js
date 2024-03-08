/* eslint-env node */

module.exports = function (api) {
  var validEnv = ['development', 'test', 'production'];
  var currentEnv = api.env();
  var isDevelopmentEnv = api.env('development');
  var isProductionEnv = api.env('production');
  var isTestEnv = api.env('test');
  var isEndToEnd = process.env.E2E === 'true';

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      'Please specify a valid `NODE_ENV` or ' +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: ' +
        JSON.stringify(currentEnv) +
        '.',
    );
  }

  return {
    presets: [
      (isProductionEnv || isDevelopmentEnv || isTestEnv) && [
        '@babel/preset-env',
        {
          modules: false,
          targets: { browsers: '> 1%' },
          useBuiltIns: 'entry',
          corejs: { version: 3, proposals: false },
          exclude: ['transform-regenerator'],
          bugfixes: true,
          forceAllTransforms: true,
        },
        'preact',
      ],
    ].filter(Boolean),
    plugins: [
      isEndToEnd && ['istanbul'],
      '@babel/plugin-syntax-dynamic-import',
      isTestEnv && '@babel/plugin-transform-modules-commonjs',
      '@babel/plugin-transform-destructuring',
      [
        '@babel/plugin-proposal-class-properties',
        {
          spec: true,
          loose: true,
        },
      ],
      [
        '@babel/plugin-proposal-object-rest-spread',
        {
          useBuiltIns: true,
        },
      ],
      [
        '@babel/plugin-transform-private-property-in-object',
        {
          loose: true,
        },
      ],
      [
        '@babel/plugin-transform-private-methods',
        {
          loose: true,
        },
      ],
      [
        '@babel/plugin-transform-react-jsx',
        {
          pragma: 'h',
        },
      ],
      [
        'inline-react-svg',
        {
          svgo: {
            plugins: [
              {
                name: 'preset-default',
                params: {
                  overrides: {
                    removeViewBox: false,
                  },
                },
              },
            ],
          },
        },
      ],
      [
        'module-resolver',
        {
          // Only the @images webpack alias is here because it's being used by a
          // Babel plugin before webpack runs in the frontend build pipeline.
          alias: {
            '@images': './app/assets/images/',
          },
        },
      ],
    ].filter(Boolean),
  };
};
