//
//  PaymentViewController.swift
//  uCubeSampleApp
//
//  Created by Rémi Hillairet on 7/29/20.
//  Copyright © 2020 YouTransactor. All rights reserved.
//

import UIKit
import UCube

class PaymentViewController: AlertPresenterTableViewController {

    @IBOutlet weak var cardWaitTimeoutTextField: UITextField!
    @IBOutlet weak var transactionTypeLabel: UILabel!
    @IBOutlet weak var enterAmountOnCubeSwitch: UISwitch!
    @IBOutlet weak var contactOnlySwitch: UISwitch!
    @IBOutlet weak var forceAuthorizationSwitch: UISwitch!
    @IBOutlet weak var forceOnlinePinSwitch: UISwitch!
    @IBOutlet weak var displayResultOnCubeSwitch: UISwitch!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var paymentResultLabel: UILabel!
    @IBOutlet weak var paymentStateLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    private var transactionType: TransactionType = .purchase
    private var currency: Currency = UCubePaymentRequest.currencyGBP
    private var emvPaystateMachine : EMVPaymentStateMachine?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView)))
        enterAmountOnCubeSwitch.isEnabled = false
        paymentResultLabel.isHidden = true
        paymentStateLabel.isHidden = true
        cancelButton.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topPadding = (view.frame.height + tableView.contentOffset.y - tableView.contentSize.height) / 2
        if tableView.tableHeaderView == nil {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: topPadding > 24 ? topPadding : 24))
            headerView.backgroundColor = .clear
            tableView.tableHeaderView = headerView
        }
    }
    
    @objc
    func didTapView() {
        cardWaitTimeoutTextField.resignFirstResponder()
        amountTextField.resignFirstResponder()
    }
    
    @IBAction func cancelPayment(_ sender: Any) {
        cancelButton.isEnabled = false
        
        self.emvPaystateMachine?.cancel()
    }
    
    @IBAction func startPayment(_ sender: Any) {
        guard
            let cardWaitTimeoutText = cardWaitTimeoutTextField.text,
            let cardWaitTimeout = TimeInterval(cardWaitTimeoutText),
            let amountText = amountTextField.text,
            let amount = UInt64(amountText.replacingOccurrences(of: ".", with: ""))
            else {
                return
        }
        
        let amountValue = !enterAmountOnCubeSwitch.isOn ? UInt64(amount) : 0
        var readers = [CardEntryMode.ICC]
        
        if (!contactOnlySwitch.isOn) {
            readers.append(.NFC)
        }
        
        let messages:[PaymentMessages:String] = [
            
            PaymentMessages.LBL_prepare_context: "preparing context",
            PaymentMessages.LBL_authorization: "Authorization processing",
            PaymentMessages.LBL_smc_initialization: "initialization processing",
            PaymentMessages.LBL_smc_risk_management: "risque management processing",
            PaymentMessages.LBL_smc_finalization: "finalization processing",
            PaymentMessages.LBL_smc_remove_card: "remove card, please",
            
            PaymentMessages.LBL_nfc_complete: "complete processing",
            PaymentMessages.LBL_wait_online_pin_process: "online pin processing",
            PaymentMessages.LBL_wait_card: "insert card",
            
            PaymentMessages.LBL_approved: "Approved",
            PaymentMessages.LBL_declined: "Declined",
            PaymentMessages.LBL_unsupported_card: "Unsupported card",
            PaymentMessages.LBL_cancelled: "Cancelled",
            PaymentMessages.LBL_error: "Error",
            PaymentMessages.LBL_no_card_detected: "No card detected",
            PaymentMessages.LBL_wrong_activated_reader: "wrong activated reader",
            
            PaymentMessages.LBL_try_other_interface: "try other interface",
            PaymentMessages.LBL_end_application: "end application ",
            PaymentMessages.LBL_failed: "failed",
            PaymentMessages.LBL_wrong_nfc_outcome: "wrong nfc outcome",
        
            PaymentMessages.LBL_wrong_cryptogram_value: "wrong cryptogram value",
            PaymentMessages.LBL_missing_required_cryptogram: "missing required cryptogram",
            PaymentMessages.GLOBAL_LBL_xposition: "00",
            PaymentMessages.GLOBAL_LBL_yposition: "0C",
            PaymentMessages.GLOBAL_LBL_font_id: "00",
        ]
        
        // non optional variables
        var paymentRequest = UCubePaymentRequest(amount: amountValue, currency: currency, transactionType: transactionType, readers: readers, messages: messages, authorizationTask: AuthorizationTask(presenter: self), preferredLanguages: ["en"] )
        
        // optional variables
        paymentRequest.displayResult = displayResultOnCubeSwitch.isOn
        paymentRequest.cardWaitTimeout = cardWaitTimeout
        paymentRequest.systemFailureInfo2 = false
        paymentRequest.forceDebug = true
        paymentRequest.transactionDate = Date()
        paymentRequest.forceAuthorization = forceAuthorizationSwitch.isOn
        paymentRequest.forceOnlinePIN = forceOnlinePinSwitch.isOn
        paymentRequest.authorizationPlainTags = [
            RPC.EMVTag.TAG_4F_APPLICATION_IDENTIFIER,
            RPC.EMVTag.TAG_50_APPLICATION_LABEL,
            RPC.EMVTag.TAG_5F2A_TRANSACTION_CURRENCY_CODE,
            RPC.EMVTag.TAG_5F34_APPLICATION_PRIMARY_ACCOUNT_NUMBER_SEQUENCE_NUMBER,
            RPC.EMVTag.TAG_81_AMOUNT_AUTHORISED,
            RPC.EMVTag.TAG_8E_CARDHOLDER_VERIFICATION_METHOD_LIST,
            RPC.EMVTag.TAG_95_TERMINAL_VERIFICATION_RESULTS,
            RPC.EMVTag.TAG_9B_TRANSACTION_STATUS_INFORMATION,
            RPC.EMVTag.TAG_99_TRANSACTION_PERSONAL_IDENTIFICATION_NUMBER_DATA,
            RPC.EMVTag.TAG_9A_TRANSACTION_DATE,
            RPC.EMVTag.TAG_9F1A_TERMINAL_COUNTRY_CODE,
            RPC.EMVTag.TAG_DF37_SELECTED_CARDHOLDER_LANGUAGE
        ]
        
        paymentRequest.authorizationSecuredTags = [
            RPC.EMVTag.TAG_SECURE_5A_APPLICATION_PRIMARY_ACCOUNT_NUMBER,
            RPC.EMVTag.TAG_SECURE_57_TRACK_2_EQUIVALENT_DATA,
            RPC.EMVTag.TAG_SECURE_56_TRACK_1_DATA,
            RPC.EMVTag.TAG_SECURE_5F20_CARDHOLDER_NAME,
            RPC.EMVTag.TAG_SECURE_5F24_APPLICATION_EXPIRATION_DATE,
            RPC.EMVTag.TAG_SECURE_5F30_SERVICE_CODE,
            RPC.EMVTag.TAG_SECURE_9F0B_CARDHOLDER_NAME_EXTENDED,
            RPC.EMVTag.TAG_SECURE_9F6B_TRACK_2_DATA
        ]
        
        paymentRequest.finalizationPlainTags = [
            RPC.EMVTag.TAG_95_TERMINAL_VERIFICATION_RESULTS,
            RPC.EMVTag.TAG_4F_APPLICATION_IDENTIFIER,
            RPC.EMVTag.TAG_50_APPLICATION_LABEL,
            RPC.EMVTag.TAG_5F2A_TRANSACTION_CURRENCY_CODE,
            RPC.EMVTag.TAG_5F34_APPLICATION_PRIMARY_ACCOUNT_NUMBER_SEQUENCE_NUMBER,
            RPC.EMVTag.TAG_81_AMOUNT_AUTHORISED,
            RPC.EMVTag.TAG_8E_CARDHOLDER_VERIFICATION_METHOD_LIST,
            RPC.EMVTag.TAG_95_TERMINAL_VERIFICATION_RESULTS,
            RPC.EMVTag.TAG_9B_TRANSACTION_STATUS_INFORMATION,
            RPC.EMVTag.TAG_99_TRANSACTION_PERSONAL_IDENTIFICATION_NUMBER_DATA,
            RPC.EMVTag.TAG_9A_TRANSACTION_DATE,
            RPC.EMVTag.TAG_9F1A_TERMINAL_COUNTRY_CODE,
            RPC.EMVTag.TAG_DF37_SELECTED_CARDHOLDER_LANGUAGE,
            0xDFC302,
            0xDF8129
        ]
        
        paymentRequest.finalizationSecuredTags = [
            RPC.EMVTag.TAG_SECURE_5A_APPLICATION_PRIMARY_ACCOUNT_NUMBER,
            RPC.EMVTag.TAG_SECURE_57_TRACK_2_EQUIVALENT_DATA,
            RPC.EMVTag.TAG_SECURE_56_TRACK_1_DATA,
            RPC.EMVTag.TAG_SECURE_5F20_CARDHOLDER_NAME,
            RPC.EMVTag.TAG_SECURE_5F24_APPLICATION_EXPIRATION_DATE,
            RPC.EMVTag.TAG_SECURE_5F30_SERVICE_CODE,
            RPC.EMVTag.TAG_SECURE_9F0B_CARDHOLDER_NAME_EXTENDED,
            RPC.EMVTag.TAG_SECURE_9F6B_TRACK_2_DATA
        ]
    
        paymentRequest.riskManagementTask = RiskManagementTask(presenter: self)
      
        
        paymentResultLabel.isHidden = true
        startButton.isHidden = true
        cancelButton.isHidden = false
        emvPaystateMachine = UCubeAPI.pay(request: paymentRequest, didProgress: { (state: PaymentState, context: PaymentContext) in
            LogManager.debug(message: "Payment did progress: \(state.name)")
            self.paymentStateLabel.text = state.name
            self.paymentStateLabel.isHidden = false
        }, didFinish: { (context: PaymentContext) in
            LogManager.debug(message: "Payment did finish with status: \(context.paymentStatus?.name ?? "unknown")")
            
            // UI
            self.paymentResultLabel.text = (context.paymentStatus?.name ?? "unknown")
            self.paymentResultLabel.isHidden = false
            self.paymentStateLabel.isHidden = true
            self.cancelButton.isHidden = true
            self.cancelButton.isEnabled = true
            self.startButton.isHidden = false
            
            // Log result
            if let uCubeFirmware = context.uCubeInfo?.parseTLV()[RPC.Tag.firmwareVersion] {
                LogManager.debug(message: "uCube firmware version: \(uCubeFirmware.parseVersion())")
            }
            if let cardEntryMode = context.cardEntryMode {
                switch cardEntryMode {
                case CardEntryMode.ICC :
                    LogManager.debug(message: "Used interface was smart card")
                case CardEntryMode.NFC :
                    LogManager.debug(message: "Used interface was NFC")
                }
            }
            LogManager.debug(message: "amount: \(context.getAmount())")
            LogManager.debug(message: "currency: \(context.currency.label )")
            LogManager.debug(message: "tx date: \(context.transactionDate?.description ?? "unknown")")
            LogManager.debug(message: "tx type: \(context.transactionType?.label ?? "unknown")")
            if let selectedApplication = context.selectedApplication {
                LogManager.debug(message: "app ID: \(selectedApplication.getLabel() ?? "unknown")")
                LogManager.debug(message: "app version: \(context.applicationVersion?.description ?? "unknown")")
            }
            LogManager.debug(message: "svpp logs Level 2 tag CC: \(context.tagCC?.hexString ?? "unknown")")
            LogManager.debug(message: "svpp logs Level 2 tag F4: \(context.tagF4?.hexString ?? "unknown")")
            LogManager.debug(message: "svpp logs Level 2 tag F5: \(context.tagF5?.hexString ?? "unknown")")
           
            if let plainTagTLV = context.finalizationPlainTagsValues {
                for (tag, value) in plainTagTLV {
                    LogManager.debug(message: "Plain tag: 0x\(tag.hexString), \(tag) = 0x\(value.hexString)")
                }
            }
            if let securedTagBlock = context.finalizationSecuredTagsValues {
                LogManager.debug(message: "secured tag block: \(securedTagBlock.hexString)")
            }
        })
    }
    
    @IBAction func changeTransactionType(_ sender: Any) {
        let completion = { (type: TransactionType) in
            self.transactionType = type
            self.transactionTypeLabel.text = type.label
        }
        let alert = UIAlertController(title: "Choose a transaction type", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: TransactionType.purchase.label, style: .default) { _ in
            completion(.purchase)
        })
        alert.addAction(UIAlertAction(title: TransactionType.withdrawal.label, style: .default) { _ in
            completion(.withdrawal)
        })
        alert.addAction(UIAlertAction(title: TransactionType.refund.label, style: .default) { _ in
            completion(.refund)
        })
        alert.addAction(UIAlertAction(title: TransactionType.purchaseCashback.label, style: .default) { _ in
            completion(.purchaseCashback)
        })
        alert.addAction(UIAlertAction(title: TransactionType.manualCash.label, style: .default) { _ in
            completion(.manualCash)
        })
        alert.addAction(UIAlertAction(title: TransactionType.inquiry.label, style: .default) { _ in
            completion(.inquiry)
        })
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeCurrency(_ sender: Any) {
        let completion = { (currency: Currency) in
            self.currency = currency
            self.currencyLabel.text = currency.label
        }
        let alert = UIAlertController(title: "Choose a currency", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: UCubePaymentRequest.currencyEUR.label, style: .default) { _ in
            completion(UCubePaymentRequest.currencyEUR)
        })
        alert.addAction(UIAlertAction(title: UCubePaymentRequest.currencyUSD.label, style: .default) { _ in
            completion(UCubePaymentRequest.currencyUSD)
        })
        present(alert, animated: true, completion: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
