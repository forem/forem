---
title: Deployment and CI/CD Process
---

# Deployment and CI/CD Process

## Overview

DEV relies on GitHub and Travis to deploy continuously to Heroku. If a Pull Request is merged without the "ci skip" in its title, it will be automatically deployed to production once the build steps complete successfully. The process currently takes about 20 minutes to complete and will need a few additional minutes before the change goes live.

## Travis steps

The following steps can be explored in our [.travis.yml](https://github.com/thepracticaldev/dev.to/blob/master/.travis.yml) and [Procfile](https://github.com/thepracticaldev/dev.to/blob/master/Procfile). Some of the steps will be parallelized in the future.

1. Travis runs the test portion of Rails code.
1. Travis runs the test portion of Preact code.
1. CodeClimate-test-reporter combines the test result and coverage from Ruby and JavaScript code then uploads it to our CodeClimate dashboard.
1. `bundle-audit` checks for any known vulnerability.
1. Travis builds Storybook to ensure its integrity.
1. Travis deploys code to Heroku.
   - Heroku runs the database migrations before deployment.
1. `after_deploy` script kicks in.
   - Airbrake Deploy Tracking is notified of the deployment.
1. Travis notifies the team that the process completed.

## Deploying to Heroku

We use Heroku's Release Phase feature.

![](https://devcenter0.assets.heroku.com/article-images/1494371187-release-phase-diagram-3.png)
