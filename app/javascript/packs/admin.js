import { Application } from '@hotwired/stimulus';
import { definitions } from 'stimulus:../admin/controllers'; // eslint-disable-line import/no-unresolved
import Rails from '@rails/ujs';
import 'focus-visible';

// Initialize Rails unobtrusive scripting adapter
// https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/README.md#es2015
Rails.start();

// This loads all the Stimulus controllers at the same time for the admin
// section of the application.

const application = Application.start();
application.load(definitions);
