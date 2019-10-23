---
title: Deployment and CI/CD Process
---

# Deployment and CI/CD Process

## Overview

DEV relies on GitHub + Travis to continuous deploy to Heroku. If a Pull Request is merged without the "ci skip" in it's title, it will be automatically deployed to production once the test suite passes. The process currently takes about 20 minute to complete and will need a few addtional minute before the change live.

## Travis steps

The following steps can be explored in our [.travis.yml](https://github.com/thepracticaldev/dev.to/blob/master/.travis.yml) and [Procfile](https://github.com/thepracticaldev/dev.to/blob/master/Procfile)

1. Travis runs the test portion of Rails code
1. Travis runs the test portion of Preact code
1. CodeClimate-test-reporter combines the test result and coverage from Ruby and JavaScript code then upload it to our CodeClimate dashboard.
1. `bundle-audit` check for any known vulnerability
1. Travis builds Storybook to ensure it's integrity.
1. Travis deploys code to Heroku
   - Heroku runs migration krior to deployment
1. `after_deploy` scripts kicks in
   - Airbrake Deploy Tracking is notified of the doployment
1. Travis notifies the team the process completed

## Deploying to Heroku

We use Heroku's Release Phase feature.

![](https://devcenter0.assets.heroku.com/article-images/1494371187-release-phase-diagram-3.png)
