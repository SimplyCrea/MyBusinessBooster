
import Foundation
import MessageUI
import UIKit

class CommunicationHelper: NSObject, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    static let shared = CommunicationHelper()

    private override init() {}

    // Fonction pour envoyer un SMS
    func sendSMS(to phoneNumber: String, body: String, from viewController: UIViewController) {
        guard MFMessageComposeViewController.canSendText() else {
            print("L'envoi de SMS n'est pas pris en charge sur cet appareil.")
            return
        }

        let messageVC = MFMessageComposeViewController()
        messageVC.body = body
        messageVC.recipients = [phoneNumber]
        messageVC.messageComposeDelegate = self

        viewController.present(messageVC, animated: true, completion: nil)
    }

    // Fonction pour envoyer un e-mail
    func sendEmail(to email: String, subject: String, body: String, from viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            print("L'envoi d'e-mails n'est pas pris en charge sur cet appareil.")
            return
        }

        let mailVC = MFMailComposeViewController()
        mailVC.setToRecipients([email])
        mailVC.setSubject(subject)
        mailVC.setMessageBody(body, isHTML: false)
        mailVC.mailComposeDelegate = self

        viewController.present(mailVC, animated: true, completion: nil)
    }

    // Délégation SMS
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    // Délégation Email
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
