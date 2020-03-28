// eslint-disable-next-line no-undef
module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        modules: false,
        targets: {
          browsers: '> 1%',
        },
        useBuiltIns: 'entry',
        corejs: { version: 3, proposals: false },
        exclude: ['transform-regenerator'],
      },
    ],
    'preact',
  ],
  env: {
    test: {
      plugins: ['@babel/plugin-transform-modules-commonjs'],
    },
  },
  plugins: [
    '@babel/plugin-syntax-dynamic-import',
    '@babel/plugin-proposal-object-rest-spread',
    [
      '@babel/plugin-proposal-class-properties',
      {
        spec: true,
      },
    ],
    [
      '@babel/plugin-transform-react-jsx',
      {
        pragma: 'h',
      },
    ],
  ],
};
