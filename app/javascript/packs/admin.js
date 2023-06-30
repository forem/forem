import { Application } from '@hotwired/stimulus';
import { LocalTimeElement } from '@github/time-elements'; // eslint-disable-line no-unused-vars
import Rails from '@rails/ujs';
import 'focus-visible';

import AhoyController from '../admin/controllers/ahoy_controller';
import AlertController from '../admin/controllers/alert_controller';
import ArticleController from '../admin/controllers/article_controller';
import ArticlePinnedModalController from '../admin/controllers/article_pinned_modal_controller';
import ConfigController from '../admin/controllers/config_controller';

// Initialize Rails unobtrusive scripting adapter
// https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/README.md#es2015
Rails.start();

// This loads all the Stimulus controllers at the same time for the admin
// section of the application.

window.Stimulus = Application.start();

window.Stimulus.register('ahoy', AhoyController);
window.Stimulus.register('alert', AlertController);
window.Stimulus.register('article', ArticleController);
window.Stimulus.register('article', ArticlePinnedModalController);
window.Stimulus.register('config', ConfigController);
