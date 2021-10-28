//
//  PaymentViewController.swift
//  HelloCordova
//
//  Created by Gideons Developer on 26/10/21.
//

import Foundation
import Stripe
import UIKit

class PaymentViewController: UIViewController {
    
    var paymentIntentClientSecret: String?
    var publicKey: String?
    var setupIntentUrl: String?
    var accessToken: String?

    public init(publicKey: String?, setupIntentUrl: String?, accessToken: String?) {

        super.init(nibName: nil, bundle: nil)
        self.publicKey = publicKey
        self.setupIntentUrl = setupIntentUrl
        self.accessToken = accessToken
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
    
    lazy var payButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5
        button.backgroundColor = .systemBlue //UIColor(red: 0.0, green: 154.0, blue: 173.0, alpha: 1.0)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        button.setTitle("Zahlungsdaten speichernay", for: .normal)
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [cardTextField, payButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraintEqualToSystemSpacingAfter(view.leftAnchor, multiplier: 2),
            view.rightAnchor.constraintEqualToSystemSpacingAfter(stackView.rightAnchor, multiplier: 2),
            stackView.topAnchor.constraintEqualToSystemSpacingBelow(view.topAnchor, multiplier: 6),
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
            
            guard let data = data,
                  
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let responseData = json!["data"] as? [String:AnyObject],
                let paymentIntentClientSecret = responseData["intent"] as? String,
                let self = self else {
                    // Error: couldn't get setup Intent
                    return
                }
            self.paymentIntentClientSecret = paymentIntentClientSecret
        })
        task.resume()
    }

    @objc
    func pay() {
        print(paymentIntentClientSecret)
        print("HELLOE")
        guard let paymentIntentClientSecret = paymentIntentClientSecret else {
            return;
        }
        // Collect card details
        let cardParams = cardTextField.cardParams
    
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPSetupIntentConfirmParams(clientSecret: paymentIntentClientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams

        // Submit the payment
        let paymentHandler = STPPaymentHandler.shared()
        paymentHandler.confirmSetupIntent(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            switch (status) {
            case .failed:
                self.displayAlert(title: "Payment failed", message: error?.localizedDescription ?? "")
                break
            case .canceled:
                self.displayAlert(title: "Payment canceled", message: error?.localizedDescription ?? "")
                break
            case .succeeded:
                self.displayAlert(title: "Payment succeeded", message: paymentIntent?.description ?? "")
                break
            @unknown default:
                fatalError()
                break
            }
        }
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
