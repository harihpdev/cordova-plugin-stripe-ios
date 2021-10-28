//
//  PaymentViewController.swift
//  HelloCordova
//
//  Created by Gideons Developer on 26/10/21.
//

import Stripe
import UIKit
import FittedSheets

@objc(StripePlugin) class StripePlugin: CDVPlugin {

    @objc (showCardPaymentInterface:)
    func showCardPaymentInterface(command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult (
            status: CDVCommandStatus_ERROR,
            messageAs: "Invalid Params !!!"
        );


        let publicKey:String? = command.arguments[0] as? String ?? nil
        let setupIntentUrl:String? = command.arguments[1] as? String ?? nil
        let accessToken:String? = command.arguments[2] as? String ?? nil
        
        guard let publicKey = publicKey, let setupIntentUrl = setupIntentUrl, let accessToken = accessToken else {
            //Error Invalid Input params
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
            return;
        }
        
        let paymentViewController = PaymentViewController(
            publicKey: publicKey,
            setupIntentUrl: setupIntentUrl,
            accessToken: accessToken
        )
        
        let sheetController = SheetViewController(
            controller: paymentViewController,
            sizes: [.fixed(200)]
        )

        viewController.present(sheetController, animated: true, completion: nil)
    }
}
