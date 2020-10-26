import { Application } from 'stimulus';
import { definitionsFromContext } from 'stimulus/webpack-helpers';

// This loads all the Stimulus controllers at the same time for the admin
// section of the application.

const application = Application.start();
const context = require.context('admin/controllers', true, /.js$/);
application.load(definitionsFromContext(context));
