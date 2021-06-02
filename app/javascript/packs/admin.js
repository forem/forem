import { Application } from 'stimulus';
import { definitionsFromContext } from 'stimulus/webpack-helpers';
import Rails from '@rails/ujs';

// Initialize Rails unobtrusive scripting adapter
// https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/README.md#es2015
Rails.start();

// This loads all the Stimulus controllers at the same time for the admin
// section of the application.

const application = Application.start();
const context = require.context('admin/controllers', true, /.js$/);
application.load(definitionsFromContext(context));
