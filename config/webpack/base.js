const { webpackConfig, merge } = require('@rails/webpacker')
const customConfig = require('./custom')

module.exports = merge(webpackConfig, customConfig)
