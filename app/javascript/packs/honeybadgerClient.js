import Honeybadger from '@honeybadger-io/js/dist/browser/honeybadger.js';
import { patchHoneybadgerClient } from '@utilities/honeybadgerSanitizer';

patchHoneybadgerClient(Honeybadger);

window.Honeybadger = Honeybadger;

export default Honeybadger;
