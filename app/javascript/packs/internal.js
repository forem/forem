import { Application } from 'stimulus';
import { definitionsFromContext } from 'stimulus/webpack-helpers';

const application = Application.start();
const context = require.context('admin/controllers', true, /.js$/);
application.load(definitionsFromContext(context));
