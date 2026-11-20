import { createCaptchaInitializer } from './initializeCaptcha';

export const initializeHcaptcha = createCaptchaInitializer({
  apiName: 'hcaptcha',
  selector: '.h-captcha',
  callbackName: 'onForemHcaptchaLoad',
  scriptUrl:
    'https://js.hcaptcha.com/1/api.js?render=explicit&onload=onForemHcaptchaLoad&recaptchacompat=off',
  options: (container) => ({
    sitekey: container.dataset.sitekey,
    size: 'normal',
  }),
});
