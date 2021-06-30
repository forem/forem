/* eslint-env node */

module.exports = function (api) {
  var validEnv = ['development', 'test', 'production'];
  var currentEnv = api.env();
  var isDevelopmentEnv = api.env('development');
  var isProductionEnv = api.env('production');
  var isTestEnv = api.env('test');

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
      '@babel/plugin-syntax-dynamic-import',
      isTestEnv && 'babel-plugin-dynamic-import-node',
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
        '@babel/plugin-proposal-private-property-in-object',
        {
          loose: true,
        }
      ],
      [
        '@babel/plugin-proposal-private-methods',
        {
          loose: true,
        }
      ],
      [
        '@babel/plugin-transform-react-jsx',
        {
          pragma: 'h',
        },
      ],
    ].filter(Boolean),
  };
};
