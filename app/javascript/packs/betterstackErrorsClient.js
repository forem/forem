import { createBetterstackErrorsClient } from '@utilities/betterstackErrorsAdapter';

const betterstackErrorsClient = createBetterstackErrorsClient();

window.BetterstackErrors = betterstackErrorsClient;
window.Honeybadger = betterstackErrorsClient;

export { betterstackErrorsClient };
