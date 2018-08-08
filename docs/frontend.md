## ⚛ Front-End Development

Before doing any development in the front-end, ensure that [Node.js](https://nodejs.org) is installed. To install Node.js, you can do one of the following:

* [Download and install the LTS version](https://nodejs.org/en/download), or
* [Download and install nvm](https://github.com/creationix/nvm) and follow their instructions to install the Node.js LTS version (recommended), or
* [Download and install n](https://github.com/tj/n) and follow their instructions to install the Node.js LTS version, or
* Install Node.js via Homebrew (macOS only) `brew install node`

For bundling, we use Webpack via the [webpacker](https://github.com/rails/webpacker) since the backend is Ruby on Rails.

There is some legacy code which is old school JS, but for all things new, [Preact](https://preactjs.com) is where it's at. If you're new to Preact, check out their [documentation](https://preactjs.com/guide/getting-started). Also, consider following the [#preact](https://dev.to/t/preact) tag on [dev.to](https://dev.to).

### 👷‍ Building components

We use [Storybook](https://storybook.js.org) to develop components. It allows you to focus on building components without the burden of the whole application running. If you're new to Storybook, check out their [documentation](https://storybook.js.org/basics/guide-react). Also, consider following the [#storybook](https://dev.to/t/storybook) tag on [dev.to](https://dev.to).

To get Storybook running on your local:

* 📦 Run `npm install` or `yarn` to ensure all your dependencies are installed.
* 🏁 Run `npm run storybook` or `yarn storybook` to start Storybook.
* 🏗️ Start working on your component and see the changes in Storybook as you save.
