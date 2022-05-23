// eslint-disable-next-line no-restricted-syntax
export default function (config, env, helpers) {
  const css = helpers.getLoadersByName(config, 'css-loader')[0];
  css.loader.options.modules = false;
}
