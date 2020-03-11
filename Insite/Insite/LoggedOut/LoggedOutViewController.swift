//
//  LoggedOutViewController.swift
//  Insite
//
//  Created by Varun Iyer on 2/27/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs
import RxSwift
import UIKit
import SnapKit
import RxGesture
import PhoneNumberKit
import RSLoadingView
import FirebaseAuth
import CoreLocation
import M13Checkbox

protocol LoggedOutPresentableListener: class {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
    func authenticate(verificationID: String, verificationCode: String)
}

final class LoggedOutViewController: UIViewController, LoggedOutPresentable, LoggedOutViewControllable {

    weak var listener: LoggedOutPresentableListener?
    
    init(w: CGFloat, h: CGFloat) {
        self.w = w
        self.h = h
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Method is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(nil, forKey: "notificationsPermission")
        view.backgroundColor = UIColor(red: 15/255, green: 16/255, blue: 18/255, alpha: 1.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if stage == "welcome" {
            insiteWelcomeAnimation()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "notificationsPermission", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            kbHeight = keyboardSize.height
            if stage == "phone" {
                _setupNextButton()
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
         of object: Any?,
     change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?){
        if keyPath == "notificationsPermission" {
            if stage == "notifications" {
                DispatchQueue.main.async {
                    self.transitionToLastCheckAnimation()
                }
            }
        }
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "notificationsPermission")
    }
    
    // MARK: - Private
    
    private func _setupWelcome() {
        insiteLabel = UILabel()
        insiteLabel.addCharactersSpacing(spacing: 10, text: "INSITE")
        insiteLabel.font = UIFont.systemFont(ofSize: 48, weight: UIFont.Weight.thin)
        insiteLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        insiteLabel.textAlignment = .center
        insiteLabel.numberOfLines = 0
        insiteLabel.sizeToFit()
        insiteLabel.alpha = 0
        
        view.addSubview(insiteLabel)
        insiteLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(self.view.snp.top).offset(h/4)
        }
        
        insiteSubtitleLabel = UILabel()
        insiteSubtitleLabel.addCharactersSpacing(spacing: 2.5, text: "Discover Your Places")
        insiteSubtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.bold)
        insiteSubtitleLabel.textColor = .white
        insiteSubtitleLabel.textAlignment = .center
        insiteSubtitleLabel.numberOfLines = 0
        insiteSubtitleLabel.sizeToFit()
        insiteSubtitleLabel.alpha = 0
        
        view.addSubview(insiteSubtitleLabel)
        insiteSubtitleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(insiteLabel.snp.bottom).offset(20)
        }
        
        iLabel = UILabel()
        iLabel.text = "I"
        iLabel.font = UIFont.systemFont(ofSize: 200, weight: UIFont.Weight.ultraLight)
        iLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        iLabel.textAlignment = .center
        iLabel.numberOfLines = 0
        iLabel.sizeToFit()
        iLabel.alpha = 0
        
        view.addSubview(iLabel)
        iLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY)
        }
        
        signInBackgroundView = RoundShadowView(frame: CGRect(x: w/4, y: 3*h/4 - 60, width: w/2, height: 60), cornerRadius: 65/2, shadowRadius: 2, shadowOffset: CGSize(width: 0.0, height: 1.0), shadowOpacity: 0.8, shadowColor: UIColor.darkGray.cgColor)
        signInBackgroundView.backgroundColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        signInBackgroundView.layer.cornerRadius = 60/2
        signInBackgroundView.alpha = 0
        view.addSubview(signInBackgroundView)
        
        signInLabel = UILabel()
        signInLabel.addCharactersSpacing(spacing: 3, text: "SIGN IN")
        signInLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.light)
        signInLabel.textColor = .black
        signInLabel.textAlignment = .center
        signInLabel.alpha = 0
        signInLabel.sizeToFit()
        view.addSubview(signInLabel)
        signInLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(signInBackgroundView.snp.centerX)
            make.centerY.equalTo(signInBackgroundView.snp.centerY)
        }
        
        self.signInBackgroundView.rx
            .tapGesture()
            .when(.recognized)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.generator.impactOccurred()
                self?.transitionToPhoneAnimation()
            })
            .disposed(by: disposeBag)
    }
    
    private func _setupNextButton() {
        self.nextButton = UIImageView(image: UIImage(named: "next")!)
        self.nextButton.contentMode = .scaleAspectFit
        self.nextButton.alpha = 0
        
        self.view.addSubview(self.nextButton)
        self.nextButton.snp.makeConstraints { (make) in
            make.right.equalTo(self.view.snp.right).offset(-15)
            make.bottom.equalTo(self.view.snp.bottom).offset(-self.kbHeight - 15)
            make.height.equalTo(50)
            make.width.equalTo(50)
        }
        
        self.nextButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.generator.impactOccurred()
                if self!.stage == "phone" {
                    self?.processPhone()
                } else if self!.stage == "code" {
                    self?.processCode()
                }
            })
            .disposed(by: disposeBag)
        
        self.nextButtonEntranceAnimation()
    }
    
    private func _setupPhoneView() {
        whatsYourNumberLabel = UILabel()
        whatsYourNumberLabel.addCharactersSpacing(spacing: 2.5, text: "I NEED YOUR\nPHONE NUMBER\nTO VERIFY YOU")
        whatsYourNumberLabel.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.thin)
        whatsYourNumberLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        whatsYourNumberLabel.textAlignment = .center
        whatsYourNumberLabel.numberOfLines = 0
        whatsYourNumberLabel.sizeToFit()
        whatsYourNumberLabel.alpha = 0
        
        phoneTextField = PhoneNumberTextField()
        phoneTextField.textColor = .white
        phoneTextField.tintColor = .white
        phoneTextField.textAlignment = .left
        phoneTextField.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.regular)
        phoneTextField.attributedPlaceholder = NSAttributedString(string: "(XXX) XXX-XXXX", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        phoneTextField.alpha = 0
        phoneTextField.textContentType = .telephoneNumber
        phoneTextField.keyboardAppearance = UIKeyboardAppearance.dark
        phoneTextField.keyboardType = UIKeyboardType.phonePad
        phoneTextField.defaultTextAttributes.updateValue(2.5, forKey: NSAttributedString.Key.kern)
        
        countryCodeLabel = UILabel()
        countryCodeLabel.addCharactersSpacing(spacing: 2.5, text: "+1")
        countryCodeLabel.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.bold)
        countryCodeLabel.textColor = .white
        countryCodeLabel.textAlignment = .center
        countryCodeLabel.numberOfLines = 0
        countryCodeLabel.sizeToFit()
        countryCodeLabel.alpha = 0
        
        view.addSubview(whatsYourNumberLabel)
        whatsYourNumberLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(h/5)
        }
        
        view.addSubview(countryCodeLabel)
        countryCodeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.frame.height/3)
            make.left.equalTo(whatsYourNumberLabel.snp.left).offset(-40)
        }
        
        view.addSubview(phoneTextField)
        phoneTextField.snp.makeConstraints { (make) in
            make.left.equalTo(self.countryCodeLabel.snp.right).offset(10)
            make.centerY.equalTo(self.countryCodeLabel.snp.centerY)
            make.width.equalTo(w)
            make.height.equalTo(40)
        }
    }
    
    private func _setupLoadingView() {
        let loadingView = RSLoadingView(effectType: RSLoadingView.Effect.twins)
        loadingView.shouldDimBackground = false
        loadingView.sizeInContainer = CGSize(width: 125, height: 125)
        loadingView.speedFactor = 1.0
        loadingView.sizeFactor = 0.75
        loadingView.spreadingFactor = 1.5
        loadingView.lifeSpanFactor = 1.0
        loadingView.mainColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        loadingView.show(on: view)
    }
    
    private func _setupCodeView() {
        whatsTheCodeLabel = UILabel()
        whatsTheCodeLabel.addCharactersSpacing(spacing: 2.5, text: "ENTER THE CODE\nI SENT YOU")
        whatsTheCodeLabel.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.thin)
        whatsTheCodeLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        whatsTheCodeLabel.textAlignment = .center
        whatsTheCodeLabel.numberOfLines = 0
        whatsTheCodeLabel.sizeToFit()
        whatsTheCodeLabel.alpha = 0
        
        codeTextField = UITextField()
        codeTextField.textColor = .white
        codeTextField.tintColor = .white
        codeTextField.textAlignment = .center
        codeTextField.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.regular)
        codeTextField.attributedPlaceholder = NSAttributedString(string: "E.G. 123456", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        codeTextField.alpha = 0
        if #available(iOS 12.0, *) {
            codeTextField.textContentType = .oneTimeCode
        } else {
            // Fallback on earlier versions
        }
        codeTextField.keyboardAppearance = UIKeyboardAppearance.dark
        codeTextField.keyboardType = UIKeyboardType.phonePad
        codeTextField.defaultTextAttributes.updateValue(2.5, forKey: NSAttributedString.Key.kern)
        
        sentToLabel = UILabel()
        sentToLabel.text = "Sent to \(phoneNum)"
        sentToLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        sentToLabel.textColor = .white
        sentToLabel.textAlignment = .center
        sentToLabel.numberOfLines = 0
        sentToLabel.sizeToFit()
        sentToLabel.alpha = 0
        
        backButton = UIImageView(image: UIImage(named: "backOnboarding")!)
        backButton.contentMode = .scaleAspectFit
        backButton.alpha = 0
        
        view.addSubview(whatsTheCodeLabel)
        whatsTheCodeLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(h/5)
        }
        
        view.addSubview(sentToLabel)
        sentToLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(whatsTheCodeLabel.snp.bottom).offset(15)
        }
        
        view.addSubview(codeTextField)
        codeTextField.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.bottom.equalTo(self.view.snp.centerY).offset(-50)
            make.width.equalTo(w)
            make.height.equalTo(40)
        }
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.nextButton.snp.centerY)
            make.left.equalTo(self.view.snp.left).offset(15)
            make.height.equalTo(50)
            make.width.equalTo(50)
        }
        
        backButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.generator.impactOccurred()
                if self!.stage == "code" {
                    self?.transitionBackToPhoneAnimation()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func _setupLocation() {
        stage = "location"
        
        locationLabel = UILabel()
        locationLabel.numberOfLines = 0
        locationLabel.addCharactersSpacing(spacing: 2.5, text: "INSITE USES YOUR LOCATION\nTO NOTIFY YOU ABOUT\nYOUR PLACES")
        locationLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)
        locationLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        locationLabel.textAlignment = .center
        locationLabel.sizeToFit()
        locationLabel.alpha = 0
        
        view.addSubview(locationLabel)
        locationLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.frame.height/5)
        }
        
        locationImageView = UIImageView(image: UIImage(named: "allowInsiteLocation")!)
        locationImageView.contentMode = .scaleAspectFit
        locationImageView.alpha = 0
        
        view.addSubview(locationImageView)
        locationImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY)
        }
        
        locationImageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.generator.impactOccurred()
                self?.locationManager.delegate = self!
                self?.locationManager.requestWhenInUseAuthorization()
            })
            .disposed(by: disposeBag)
    }
    
    private func _setupAlwaysAllow() {
        stage = "alwaysAllow"
        
        alwaysLabel = UILabel()
        alwaysLabel.numberOfLines = 0
        alwaysLabel.addCharactersSpacing(spacing: 2.5, text: "INSITE WORKS BEST ON\n\"ALWAYS\" ALLOW LOCATION")
        alwaysLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.thin)
        alwaysLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        alwaysLabel.textAlignment = .center
        alwaysLabel.sizeToFit()
        alwaysLabel.alpha = 0
        
        view.addSubview(alwaysLabel)
        alwaysLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.frame.height/5)
        }
        
        alwaysImageView = UIImageView(image: UIImage(named: "locationPermissions"))
        alwaysImageView.contentMode = .scaleAspectFit
        alwaysImageView.alpha = 0
        
        view.addSubview(alwaysImageView)
        alwaysImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY)
            make.width.equalTo(w - 30)
        }
        
        locationBackgroundView = RoundShadowView(frame: CGRect(x: w/2 - 250/2, y: 3*h/4, width: 250, height: 60), cornerRadius: 30, shadowRadius: 2, shadowOffset: CGSize(width: 0, height: 1), shadowOpacity: 0.8, shadowColor: UIColor.darkGray.cgColor)
        locationBackgroundView.backgroundColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        locationBackgroundView.layer.cornerRadius = 30
        locationBackgroundView.alpha = 0
        
        view.addSubview(locationBackgroundView)
        
        enableLocationLabel = UILabel()
        enableLocationLabel.numberOfLines = 0
        enableLocationLabel.addCharactersSpacing(spacing: 2, text: "ENABLE LOCATION")
        enableLocationLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.light)
        enableLocationLabel.textColor = .black
        enableLocationLabel.textAlignment = .center
        enableLocationLabel.sizeToFit()
        enableLocationLabel.alpha = 0
        
        view.addSubview(enableLocationLabel)
        enableLocationLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.locationBackgroundView.snp.centerX)
            make.centerY.equalTo(self.locationBackgroundView.snp.centerY)
        }
        
        locationBackgroundView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.generator.impactOccurred()
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func _setupNotifications() {
        stage = "notifications"
        
        notificationsLabel = UILabel()
        notificationsLabel.numberOfLines = 0
        notificationsLabel.addCharactersSpacing(spacing: 2.5, text: "INSITE WORKS BEST\nWITH NOTIFICATIONS")
        notificationsLabel.font = UIFont.systemFont(ofSize: 26, weight: UIFont.Weight.thin)
        notificationsLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        notificationsLabel.textAlignment = .center
        notificationsLabel.sizeToFit()
        notificationsLabel.alpha = 0
        
        view.addSubview(notificationsLabel)
        notificationsLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.top).offset(h/5)
        }
        
        notificationsImageView = UIImageView(image: UIImage(named: "notificationsPermissionInsite"))
        notificationsImageView.contentMode = .scaleAspectFit
        notificationsImageView.alpha = 0
        
        view.addSubview(notificationsImageView)
        notificationsImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY)
            make.width.equalTo(w - 30)
        }
        
        enableBackgroundView = RoundShadowView(frame: CGRect(x: w/2 - 250/2, y: 3*h/4, width: 250, height: 60), cornerRadius: 30, shadowRadius: 2, shadowOffset: CGSize(width: 0, height: 1), shadowOpacity: 0.8, shadowColor: UIColor.darkGray.cgColor)
        enableBackgroundView.backgroundColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        enableBackgroundView.layer.cornerRadius = 30
        enableBackgroundView.alpha = 0
        
        view.addSubview(enableBackgroundView)
        
        enableLabel = UILabel()
        enableLabel.numberOfLines = 0
        enableLabel.addCharactersSpacing(spacing: 1, text: "TURN ON NOTIFICATIONS")
        enableLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.light)
        enableLabel.textColor = .black
        enableLabel.textAlignment = .center
        enableLabel.sizeToFit()
        enableLabel.alpha = 0
        
        view.addSubview(enableLabel)
        enableLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.enableBackgroundView.snp.centerX)
            make.centerY.equalTo(self.enableBackgroundView.snp.centerY)
        }
        
        enableBackgroundView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.generator.impactOccurred()
                self?.registerForNotifications()
            })
            .disposed(by: disposeBag)
    }
    
    private func _setupLastCheck() {
        lastCheck = M13Checkbox(frame: CGRect(x: w/2 - 200/2, y: h/2 - 200/2, width: 200, height: 200))
        lastCheck.stateChangeAnimation = .stroke
        lastCheck.markType = .checkmark
        lastCheck.boxType = .circle
        lastCheck.tintColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        lastCheck.secondaryTintColor = .clear
        lastCheck.secondaryCheckmarkTintColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        lastCheck.checkmarkLineWidth = 10
        lastCheck.boxLineWidth = 10
        lastCheck.animationDuration = 1
        lastCheck.isUserInteractionEnabled = false
        lastCheck.alpha = 0
        view.addSubview(lastCheck)
        
        youreInLabel = UILabel()
        youreInLabel.addCharactersSpacing(spacing: 2.5, text: "THAT'S IT!\nYOU'RE IN 🙌")
        youreInLabel.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.thin)
        youreInLabel.textColor = UIColor(red: 213/255, green: 168/255, blue: 94/255, alpha: 1.0)
        youreInLabel.textAlignment = .center
        youreInLabel.numberOfLines = 0
        youreInLabel.sizeToFit()
        youreInLabel.alpha = 0
        
        view.addSubview(youreInLabel)
        youreInLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(lastCheck.snp.bottom).offset(15)
        }
    }
    
    // MARK: - Helper
    
    private func processPhone() {
        let phoneNumberKit = PhoneNumberKit()
        var phone = ""
        if phoneTextField.text!.prefix(1) != "+" {
            phone = "+1 " + phoneTextField.text!
        } else {
            phone = phoneTextField.text!
        }
        
        do {
            let phoneNumber = try phoneNumberKit.parse(phone)
            phoneNum = phoneNumberKit.format(phoneNumber, toType: .international)
            
            UserDefaults.standard.set(phoneNum, forKey: "phoneNumber")
            
            if phoneNum != ""  {
                self.phoneDisappearAnimation()
                self._setupLoadingView()
                Auth.auth().settings!.isAppVerificationDisabledForTesting = false
                tryPhoneNumber()
            }
        }
        catch {
            print("Generic parser error")
        }
    }
    
    private func tryPhoneNumber() {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNum, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            RSLoadingView.hide(from: self.view)
            self.verificationID = verificationID!
            self.transitionToCodeAnimation()
        }
    }
    
    private func processCode() {
        self.verificationCode = codeTextField.text!
        if self.verificationCode != "" {
            self.fadeOutCodeAnimation()
        }
    }
    
    private func registerForNotifications() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.registerForNotifications()
        }
    }
    
    // MARK: - Animation
    
    private func insiteWelcomeAnimation() {
        _setupWelcome()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn, animations: {
            self.insiteLabel.alpha = 1
            self.iLabel.alpha = 1
            self.insiteSubtitleLabel.alpha = 1
            self.signInBackgroundView.alpha = 1
            self.signInLabel.alpha = 1
        })
        
        animator.startAnimation()
    }
    
    private func nextButtonEntranceAnimation() {
        let nextAnimator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.nextButton.alpha = 1
        }
        
        nextAnimator.startAnimation()
    }
    
    private func transitionToPhoneAnimation() {
        stage = "phone"
        _setupPhoneView()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn, animations: {
            self.insiteLabel.alpha = 0
            self.iLabel.alpha = 0
            self.insiteSubtitleLabel.alpha = 0
            self.signInBackgroundView.alpha = 0
            self.signInLabel.alpha = 0
            self.whatsYourNumberLabel.alpha = 1
            self.phoneTextField.alpha = 1
            self.countryCodeLabel.alpha = 1
            self.phoneTextField.becomeFirstResponder()
        })
        
        animator.addCompletion { _ in
            self.insiteLabel.removeFromSuperview()
            self.iLabel.removeFromSuperview()
            self.insiteSubtitleLabel.removeFromSuperview()
            self.signInBackgroundView.removeFromSuperview()
            self.signInLabel.removeFromSuperview()
        }
        
        animator.startAnimation()
    }
    
    private func phoneDisappearAnimation() {
        self.view.isUserInteractionEnabled = false
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.whatsYourNumberLabel.alpha = 0
            self.phoneTextField.alpha = 0
            self.countryCodeLabel.alpha = 0
            self.phoneTextField.resignFirstResponder()
            self.nextButton.alpha = 0
        }
        
        animator.addCompletion { _ in
            self.whatsYourNumberLabel.removeFromSuperview()
            self.phoneTextField.removeFromSuperview()
            self.countryCodeLabel.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
        
        animator.startAnimation()
    }
    
    private func transitionToCodeAnimation() {
        stage = "code"
        self.view.isUserInteractionEnabled = false
        _setupCodeView()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.whatsTheCodeLabel.alpha = 1
            self.codeTextField.alpha = 1
            self.codeTextField.becomeFirstResponder()
            self.backButton.alpha = 1
            self.sentToLabel.alpha = 1
            self.nextButton.alpha = 1
            self.nextButton.transform = self.nextButton.transform.translatedBy(x: 0, y: -50)
            self.backButton.transform = self.backButton.transform.translatedBy(x: 0, y: -50)
        }
        
        animator.addCompletion { _ in
            self.view.isUserInteractionEnabled = true
        }
        
        animator.startAnimation()
    }
    
    private func fadeOutCodeAnimation() {
        self.view.isUserInteractionEnabled = false
        _setupLocation()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.whatsTheCodeLabel.alpha = 0
            self.codeTextField.alpha = 0
            self.backButton.alpha = 0
            self.sentToLabel.alpha = 0
            self.nextButton.alpha = 0
            self.locationLabel.alpha = 1
            self.locationImageView.alpha = 1
            self.codeTextField.resignFirstResponder()
        }
        
        animator.addCompletion { _ in
            self.whatsTheCodeLabel.removeFromSuperview()
            self.codeTextField.removeFromSuperview()
            self.sentToLabel.removeFromSuperview()
            self.backButton.removeFromSuperview()
            self.nextButton.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
        
        animator.startAnimation()
    }
    
    private func transitionToAlwaysAnimation() {
        self.view.isUserInteractionEnabled = false
        _setupAlwaysAllow()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.locationLabel.alpha = 0
            self.locationImageView.alpha = 0
            self.alwaysLabel.alpha = 1
            self.alwaysImageView.alpha = 1
            self.enableLocationLabel.alpha = 1
            self.locationBackgroundView.alpha = 1
        }
        
        animator.addCompletion { _ in
            self.locationLabel.removeFromSuperview()
            self.locationImageView.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
        
        animator.startAnimation()
    }
    
    private func transitionToNotificationsAnimation() {
        self.view.isUserInteractionEnabled = false
        _setupNotifications()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.alwaysLabel.alpha = 0
            self.alwaysImageView.alpha = 0
            self.enableLocationLabel.alpha = 0
            self.locationBackgroundView.alpha = 0
            self.notificationsLabel.alpha = 1
            self.notificationsImageView.alpha = 1
            self.enableLabel.alpha = 1
            self.enableBackgroundView.alpha = 1
        }
        
        animator.addCompletion { _ in
            self.alwaysLabel.removeFromSuperview()
            self.alwaysImageView.removeFromSuperview()
            self.enableLocationLabel.removeFromSuperview()
            self.locationBackgroundView.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
        
        animator.startAnimation()
    }
    
    private func transitionToLastCheckAnimation() {
        self.view.isUserInteractionEnabled = false
        _setupLastCheck()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn, animations: {
            self.lastCheck.alpha = 1
            self.notificationsLabel.alpha = 0
            self.enableLabel.alpha = 0
            self.notificationsImageView.alpha = 0
            self.enableBackgroundView.alpha = 0
        })
        
        animator.addCompletion { _ in
            self.notificationsLabel.removeFromSuperview()
            self.enableLabel.removeFromSuperview()
            self.notificationsImageView.removeFromSuperview()
            self.enableBackgroundView.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
            self.lastCheck.setCheckState(.checked, animated: true)
            self.transitionToLastCheck2Animation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25, execute: { [weak self] in
                self?.generator.impactOccurred()
            })
        }
        
        animator.startAnimation()
    }
    
    private func transitionToLastCheck2Animation() {
        animator = UIViewPropertyAnimator(duration: 1.1, curve: .easeIn, animations: {
            self.youreInLabel.alpha = 1
        })
        
        animator.addCompletion { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                self?.listener?.authenticate(verificationID: self!.verificationID, verificationCode: self!.verificationCode)
            })
        }
        
        animator.startAnimation()
    }
    
    private func transitionBackToPhoneAnimation() {
        self.view.isUserInteractionEnabled = false
        _setupPhoneView()
        
        animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn, animations: {
            self.whatsTheCodeLabel.alpha = 0
            self.codeTextField.alpha = 0
            self.backButton.alpha = 0
            self.sentToLabel.alpha = 0
            self.whatsYourNumberLabel.alpha = 1
            self.phoneTextField.alpha = 1
            self.countryCodeLabel.alpha = 1
            self.phoneTextField.becomeFirstResponder()
            self.nextButton.transform = self.nextButton.transform.translatedBy(x: 0, y: 50)
        })
        
        animator.addCompletion { _ in
            self.whatsTheCodeLabel.removeFromSuperview()
            self.codeTextField.removeFromSuperview()
            self.backButton.removeFromSuperview()
            self.sentToLabel.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
        
        animator.startAnimation()
    }
    
    private let disposeBag = DisposeBag()
    private let w: CGFloat
    private let h: CGFloat
    private var kbHeight: CGFloat!
    private let locationManager = CLLocationManager()
    
    private var animator: UIViewPropertyAnimator!
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    private var stage: String = "welcome"
    
    private var phoneNum: String = ""
    private var verificationID: String = ""
    private var verificationCode: String = ""
    
    // Start Screen
    private var insiteLabel: UILabel!
    private var iLabel: UILabel!
    private var insiteSubtitleLabel: UILabel!
    private var signInBackgroundView: RoundShadowView!
    private var signInLabel: UILabel!
    private var backButton: UIImageView!
    private var nextButton: UIImageView!
    
    // Phone Num
    private var whatsYourNumberLabel: UILabel!
    private var incorrectCodeLabel: UILabel!
    private var phoneTextField: PhoneNumberTextField!
    private var countryCodeLabel: UILabel!
    
    // Code
    private var whatsTheCodeLabel: UILabel!
    private var codeTextField: UITextField!
    private var sentToLabel: UILabel!
    
    // Location
    private var locationLabel: UILabel!
    private var locationImageView: UIImageView!
    
    private var alwaysLabel: UILabel!
    private var alwaysImageView: UIImageView!
    private var locationBackgroundView: RoundShadowView!
    private var enableLocationLabel: UILabel!
    
    // Notifications
    private var notificationsLabel: UILabel!
    private var notificationsImageView: UIImageView!
    private var enableBackgroundView: RoundShadowView!
    private var enableLabel: UILabel!
    
    // Last Check
    private var lastCheck: M13Checkbox!
    private var youreInLabel: UILabel!
}

extension LoggedOutViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            if stage == "alwaysAllow" {
                transitionToNotificationsAnimation()
            }
            break
        case .authorizedWhenInUse:
            print("AUTHORIZED WHEN IN USE")
            if stage == "location" {
                transitionToAlwaysAnimation()
            }
            break
        case .notDetermined:
            break
        default:
            print("DENIED")
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "so... we kinda need your location for this to work 😅", message: "please turn on \"location\" in settings", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                    }
                }
                alertController.addAction(settingsAction)
                self.present(alertController, animated: true, completion: nil)
            }
            break
        }
    }
}
