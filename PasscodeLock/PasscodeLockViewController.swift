//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

public class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {
    
    public enum LockState {
        case enter
        case set
        case change
        case remove
        
        func getState() -> PasscodeLockStateType {
            
            switch self {
            case .enter: return EnterPasscodeState()
            case .set: return SetPasscodeState()
            case .change: return ChangePasscodeState()
            case .remove: return EnterPasscodeState(allowCancellation: true)
            }
        }
    }
    
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var descriptionLabel: UILabel?
    @IBOutlet public var placeholders: [PasscodeSignPlaceholderView] = [PasscodeSignPlaceholderView]()
    @IBOutlet public weak var cancelButton: UIButton?
    @IBOutlet public weak var deleteSignButton: UIButton?
    @IBOutlet public weak var touchIDButton: UIButton?
    @IBOutlet public weak var placeholdersX: NSLayoutConstraint?
    
    public var successCallback: ((_ lock: PasscodeLockType) -> Void)?
    public var dismissCompletionCallback: (()->Void)?
    public var animateOnDismiss: Bool
    public var notificationCenter: NotificationCenter?
    
    internal let passcodeConfiguration: PasscodeLockConfigurationType
    internal var passcodeLock: PasscodeLockType
    internal var isPlaceholdersAnimationCompleted = true
    
    private var shouldTryToAuthenticateWithBiometrics = true
    
    // MARK: - Initializers
    
    public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        
        self.animateOnDismiss = animateOnDismiss
        
        passcodeConfiguration = configuration
        passcodeLock = PasscodeLock(state: state, configuration: configuration)
        
        let nibName = "UIPasscodeLockView"
        let bundle: Bundle = bundleForResource(name: nibName, ofType: "nib")
        
        super.init(nibName: nibName, bundle: bundle)
        
        passcodeLock.delegate = self
        notificationCenter = NotificationCenter.default
    }
    
    public convenience init(state: LockState, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        
        self.init(state: state.getState(), configuration: configuration, animateOnDismiss: animateOnDismiss)
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
        clearEvents()
    }
    
    // MARK: - View
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePasscodeView()
        deleteSignButton?.isEnabled = false
        
        setupEvents()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldTryToAuthenticateWithBiometrics {
        
            authenticateWithBiometrics()
        }
    }
    
    internal func updatePasscodeView() {
        
        titleLabel?.text = passcodeLock.state.title
        descriptionLabel?.text = passcodeLock.state.description
        cancelButton?.isHidden = !passcodeLock.state.isCancellableAction
        touchIDButton?.isHidden = !passcodeLock.isTouchIDAllowed
    }
    
    // MARK: - Events
    
    private func setupEvents() {
        
        notificationCenter?.addObserver(self, selector: #selector(self.appWillEnterForegroundHandler(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(self.appDidEnterBackgroundHandler(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    private func clearEvents() {
        
        notificationCenter?.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc public func appWillEnterForegroundHandler(notification: NSNotification) {
        
        authenticateWithBiometrics()
    }
    
    @objc public func appDidEnterBackgroundHandler(notification: NSNotification) {
        
        shouldTryToAuthenticateWithBiometrics = false
    }
    
    // MARK: - Actions
    
    @IBAction func passcodeSignButtonTap(sender: PasscodeSignButton) {
        
        guard isPlaceholdersAnimationCompleted else { return }
        
        passcodeLock.addSign(sign: sender.passcodeSign)
    }
    
    @IBAction func cancelButtonTap(sender: UIButton) {
        
        dismissPasscodeLock(lock: passcodeLock)
    }
    
    @IBAction func deleteSignButtonTap(sender: UIButton) {
        
        passcodeLock.removeSign()
    }
    
    @IBAction func touchIDButtonTap(sender: UIButton) {
        
        passcodeLock.authenticateWithBiometrics()
    }
    
    private func authenticateWithBiometrics() {
        
        if passcodeConfiguration.shouldRequestTouchIDImmediately && passcodeLock.isTouchIDAllowed {
            
            passcodeLock.authenticateWithBiometrics()
        }
    }
    
    internal func dismissPasscodeLock(lock: PasscodeLockType, completionHandler: (() -> Void)? = nil) {
        
        // if presented as modal
        if presentingViewController?.presentedViewController == self {
            
            dismiss(animated: animateOnDismiss, completion: { [weak self]  in
                
                self?.dismissCompletionCallback?()
                
                completionHandler?()
            })
            
            return
            
        // if pushed in a navigation controller
        } else if navigationController != nil {
        
            navigationController?.popViewController(animated: animateOnDismiss)
        }
        
        dismissCompletionCallback?()
        
        completionHandler?()
    }
    
    // MARK: - Animations
    
    internal func animateWrongPassword() {
        
        deleteSignButton?.isEnabled = false
        isPlaceholdersAnimationCompleted = false
        
        animatePlaceholders(placeholders: placeholders, toState: .error)
        
        placeholdersX?.constant = -40
        view.layoutIfNeeded()
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                
                self.placeholdersX?.constant = 0
                self.view.layoutIfNeeded()
            },
            completion: { completed in
                
                self.isPlaceholdersAnimationCompleted = true
                self.animatePlaceholders(placeholders: self.placeholders, toState: .inactive)
        })
    }
    
    internal func animatePlaceholders(placeholders: [PasscodeSignPlaceholderView], toState state: PasscodeSignPlaceholderView.State) {
        
        for placeholder in placeholders {
            
            placeholder.animateState(state: state)
        }
    }
    
    private func animatePlacehodlerAtIndex(index: Int, toState state: PasscodeSignPlaceholderView.State) {
        
        guard index < placeholders.count && index >= 0 else { return }
        
        placeholders[index].animateState(state: state)
    }

    // MARK: - PasscodeLockDelegate
    
    public func passcodeLockDidSucceed(lock: PasscodeLockType) {
        
        deleteSignButton?.isEnabled = true
        animatePlaceholders(placeholders: placeholders, toState: .inactive)
        dismissPasscodeLock(lock: lock, completionHandler: { [weak self]  in
            self?.successCallback?(lock)
        })
    }
    
    public func passcodeLockDidFail(lock: PasscodeLockType) {
        
        animateWrongPassword()
    }
    
    public func passcodeLockDidChangeState(lock: PasscodeLockType) {
        
        updatePasscodeView()
        animatePlaceholders(placeholders: placeholders, toState: .inactive)
        deleteSignButton?.isEnabled = false
    }
    
    public func passcodeLock(lock: PasscodeLockType, addedSignAtIndex index: Int) {
        
        animatePlacehodlerAtIndex(index: index, toState: .active)
        deleteSignButton?.isEnabled = true
    }
    
    public func passcodeLock(lock: PasscodeLockType, removedSignAtIndex index: Int) {
        
        animatePlacehodlerAtIndex(index: index, toState: .active)
        
        if index == 0 {
            
            deleteSignButton?.isEnabled = false
        }
    }
}
