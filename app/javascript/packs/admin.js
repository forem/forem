import '../shared/preact/preactRuntime';
import { Application } from '@hotwired/stimulus';
import { definitions } from 'stimulus:../admin/controllers'; // eslint-disable-line import/no-unresolved
import Rails from '@rails/ujs';
import 'focus-visible';
import { initializeFrontendErrorTracking } from '@utilities/frontendErrorTracking';
import { mountBillboardShadowHosts } from '@utilities/billboardShadowDom';

initializeFrontendErrorTracking();

// Initialize Rails unobtrusive scripting adapter
// https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/README.md#es2015
Rails.start();

const application = Application.start();
application.load(definitions);

mountBillboardShadowHosts(document);
