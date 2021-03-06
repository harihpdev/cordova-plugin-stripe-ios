//
//  PaymentViewController.swift
//  stripe-ios
//
//  Created by Gideons Developer on 26/10/21.
//

import Foundation
import Stripe
import UIKit
import SwiftUI

class PaymentViewController: UIViewController {
    
    var paymentIntentClientSecret: String?
    var publicKey: String?
    var setupIntentUrl: String?
    var accessToken: String?
    var paymentStatus: PaymentStatus = PaymentStatus.INITILIZED
    var paymentResponse: String

    public init(publicKey: String?, setupIntentUrl: String?, accessToken: String?) {
        self.publicKey = publicKey
        self.setupIntentUrl = setupIntentUrl
        self.accessToken = accessToken
        self.paymentResponse = ""
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    lazy var cardTextField: STPPaymentCardTextField = {
        let cardTextField = STPPaymentCardTextField()
        cardTextField.textColor = .darkText
        cardTextField.countryCode = "de"
        return cardTextField
    }()
    
    lazy var cardHolderTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.backgroundColor = UIColor(red: 0xf3/255, green: 0xf2/255, blue: 0xf2/255, alpha: 1.0)
        textField.textColor = .darkText
        var color: UIColor = UIColor(
            red: 99/225, green: 99/225, blue: 102/225, alpha: 1.0
        )
        textField.layer.borderColor = color.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 5.0
        textField.attributedPlaceholder = NSAttributedString(
            string: "Karteninhaber",
            attributes: [NSAttributedStringKey.foregroundColor: color]
        )
        return textField
    }()
    
    lazy var payButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5 //#009AAD
        button.backgroundColor = UIColor(red: 0x00/255, green: 0x9A/255, blue: 0xAD/255, alpha: 1.0)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.setTitleColor(UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0), for: .normal)
        button.setTitle("Zahlungsdaten speichern", for: .normal)
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(
            top: 12.0, left: 0.0, bottom: 12.0, right: 0.0
        )
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad() // #F3F2F2
        view.backgroundColor = UIColor(red: 0xf3/255, green: 0xf2/255, blue: 0xf2/255, alpha: 1.0)
        let stackView = UIStackView(arrangedSubviews: [cardHolderTextField, cardTextField, payButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraintEqualToSystemSpacingAfter(view.leftAnchor, multiplier: 2),
            view.rightAnchor.constraintEqualToSystemSpacingAfter(stackView.rightAnchor, multiplier: 2),
            stackView.topAnchor.constraintEqualToSystemSpacingBelow(view.topAnchor, multiplier: 4),
        ])

       startCheckout()
    }
    
    func startCheckout() {
        // Request a PaymentIntent from your server and store its client secret
        StripeAPI.defaultPublishableKey = publicKey
        let url = URL(string: setupIntentUrl!)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            do {
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                    let responseData = json!["data"] as? [String:AnyObject],
                    let paymentIntentClientSecret = responseData["intent"] as? String,
                    let self = self else {
                        // Error: couldn't get setup Intent
                        throw error!
                    }
                self.paymentIntentClientSecret = paymentIntentClientSecret
            } catch _ {
                self?.paymentStatus = PaymentStatus.INTENT_FETCH_FAILED
                self?.displayAlert(title: "Payment Failed", message: "Please try after sometime.")
            }
        })
        task.resume()
    }

    @objc
    func pay() {
        guard let paymentIntentClientSecret = paymentIntentClientSecret else {
            return;
        }
        let cardHolderName = cardHolderTextField.text
        
        guard let name = cardHolderName, name != "", name.count > 3  else {
            self.displayAlert(title: "Bitte trage einen g??ltigen Wert ein", message: "")
            return
        }
        
        if !cardTextField.isValid {
            self.displayAlert(title: "Bitte trage g??ltige Zahlungsdaten ein.", message: "")
            return
        }
        // Collect card details
        let cardParams = cardTextField.cardParams
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = cardHolderName
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        let paymentIntentParams = STPSetupIntentConfirmParams(clientSecret: paymentIntentClientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams

        // Submit the payment
        let paymentHandler = STPPaymentHandler.shared()
        paymentHandler.confirmSetupIntent(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            switch (status) {
            case .failed:
                self.dismissSheet(PaymentStatus.FAILED)
                break
            case .canceled:
                self.dismissSheet(PaymentStatus.CANCELED)
                break
            case .succeeded:
                let id = paymentIntent?.stripeID
                let paymentId = paymentIntent?.paymentMethodID
                if let id = id, let paymentId = paymentId, let name = cardHolderName {
                    let resp: [String: String] =
                    [
                        "id": id,
                        "paymentId": paymentId,
                        "ownerName": name
                    ]
                    let jsonEncoder = JSONEncoder()
                    if let jsonData = try? jsonEncoder.encode(resp) {
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.paymentResponse = jsonString
                        }
                    }
                }
                
                self.dismissSheet(PaymentStatus.SUCCESS)
                break
            @unknown default:
                fatalError()
                break
            }
        }
    }
    
    func dismissSheet(_ status: PaymentStatus) {
        self.paymentStatus = status
        self.sheetViewController?.attemptDismiss(animated: true)
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension PaymentViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
}

class CustomTextField: UITextField {

    let padding = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}
