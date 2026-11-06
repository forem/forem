import { createCaptchaInitializer } from './initializeCaptcha';

export const initializeTurnstile = createCaptchaInitializer({
  apiName: 'turnstile',
  selector: '.cf-turnstile',
  callbackName: 'onForemTurnstileLoad',
  scriptUrl:
    'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=onForemTurnstileLoad',
  options: (container) => ({
    sitekey: container.dataset.sitekey,
    action: container.dataset.action,
  }),
});
