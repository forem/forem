module.exports = function(api) {
  api.cache(true);

  return {
    presets: [
      [
        '@babel/preset-env',
        {
          modules: false,
          targets: {
            browsers: '> 1%',
            uglify: true,
          },
          useBuiltIns: 'entry',
          corejs: '3.2.1',
        },
      ],
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
      ['@babel/plugin-transform-react-jsx', { pragma: 'h' }],
    ],
  };
};
