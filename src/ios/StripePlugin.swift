//
//  PaymentViewController.swift
//  stripe-ios
//
//  Created by Gideons Developer on 26/10/21.
//

import Stripe
import UIKit
import FittedSheets
import SwiftUI

enum PaymentStatus {
    case INITILIZED
    case SUCCESS
    case CANCELED
    case FAILED
    case INVALID_PARAMS
    case INTENT_FETCH_IN_PROGRESS
    case INTENT_FETCH_FAILED
    
    var desc: String {
        switch self {
        case .SUCCESS:
            return "SUCCESS"
        case .INITILIZED:
            return "INITILIZED"
        case .CANCELED:
            return "CANCELED"
        case .FAILED:
            return "FAILED"
        case .INVALID_PARAMS:
            return "INVALID_PARAMS"
        case .INTENT_FETCH_IN_PROGRESS:
            return "INTENT_FETCH_IN_PROGRESS"
        case .INTENT_FETCH_FAILED:
            return "INTENT_FETCH_FAILED"
        }
    }
}

@objc(StripePlugin) class StripePlugin: CDVPlugin {

    @objc (showCardPaymentInterface:)
    func showCardPaymentInterface(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult (
            status: CDVCommandStatus_ERROR,
            messageAs: PaymentStatus.INVALID_PARAMS.desc
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
        sheetController.dismissOnOverlayTap = false


        viewController.present(sheetController, animated: true, completion: nil)
        
        sheetController.didDismiss = { _ in
            // This is called after the sheet is dismissed
            let status: PaymentStatus = paymentViewController.paymentStatus
            let result: String = paymentViewController.paymentResponse
            
            switch status {
            case .SUCCESS:
                pluginResult = CDVPluginResult (
                    status: CDVCommandStatus_OK,
                    messageAs: result
                )
                break
            default:
                pluginResult = CDVPluginResult (
                    status: CDVCommandStatus_ERROR,
                    messageAs: status.desc
                )
            }
            
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }
}
