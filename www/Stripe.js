var exec = require('cordova/exec');

exports.showCardPaymentInterface = function (publicKey, setupIntentUrl, accessToken, success, error) {
    exec(success, error, 'StripePlugin', 'showCardPaymentInterface', [publicKey, setupIntentUrl, accessToken]);
};

