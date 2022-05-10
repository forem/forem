/* eslint-env node */
const Environment = require('jest-environment-jsdom').default;

module.exports = class CustomTestEnvironment extends Environment {
  constructor(config, context) {
    super(config, context);
  }

  async setup() {
    await super.setup();
    // See https://github.com/jsdom/jsdom/issues/2524#issuecomment-736672511
    if (typeof this.global.TextEncoder === 'undefined') {
      const { TextEncoder, TextDecoder } = require('util');
      this.global.TextEncoder = TextEncoder;
      this.global.TextDecoder = TextDecoder;
    }
  }

  async teardown() {
    await super.teardown();
  }

  getVmContext() {
    return super.getVmContext();
  }
};
