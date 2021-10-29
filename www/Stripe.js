var exec = require('cordova/exec');

exports.showCardPaymentInterface = function (publicKey, setupIntentUrl, accessToken) {
    return new Promise(function(resolve, reject) {
        exec(resolve, reject, 'StripePlugin', 'showCardPaymentInterface', [publicKey, setupIntentUrl, accessToken]);
    })
};