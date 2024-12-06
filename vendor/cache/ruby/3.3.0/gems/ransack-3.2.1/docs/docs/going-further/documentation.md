---
sidebar_position: 11
title: Documentation
---

Ransack uses [Docusaurus](https://docusaurus.io/) for documentation. To contribute to the docs simply use the "Edit this page" link from any page to directly edit, or else pull the repo and edit locally.

### Local Development

Switch to docs folder

```
cd docs
```

Install docusaurus and other dependencies

```
yarn install
```


Start a local development server and open up a browser window. Most changes are reflected live without having to restart the server.

```
yarn start
```

### Build

```
yarn build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

### Deployment

Using SSH:

```
USE_SSH=true yarn deploy
```
