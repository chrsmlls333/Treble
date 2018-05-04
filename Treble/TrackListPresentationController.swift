//
//  TrackListPresentationController.swift
//  Treble
//
//  Created by Andy Liang on 2016-06-18.
//  Copyright © 2016 Andy Liang. All Rights Reserved. MIT License.
//
//  Modified by Chris Eugene Mills for the Vancouver Art Gallery, April 2018
//

import UIKit

class TrackListPresentationController: UIPresentationController {
    
    private let dimmingView = UIView()
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.frame = presentedViewController.view.bounds
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(TrackListPresentationController.dimmingViewTapped(_:)))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    @objc func dimmingViewTapped(_ tapRecognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = self.containerView!.bounds
        dimmingView.alpha = 0.2
        dimmingView.backgroundColor = .black
        
        containerView!.insertSubview(dimmingView, at: 0)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.dimmingView.alpha = 0.4
            }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            self.dimmingView.alpha = 0
            }, completion: nil)
    }
    
    override func containerViewWillLayoutSubviews() {
        dimmingView.frame = containerView!.bounds
        presentedView!.frame = frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let height = presentedViewController.preferredContentSize.height
        let presentedViewFrame = presentingViewController.traitCollection.horizontalSizeClass == .regular
            ? containerView!.frame
            : CGRect(x: 0.0, y: containerView!.frame.height-height, width: containerView!.frame.width, height: height)
        return presentedViewFrame
    }
    
    override var shouldPresentInFullscreen: Bool {
        return false
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        UIView.animate(withDuration: 0.3) {
            self.presentedView!.frame = self.containerView != nil
                ? self.frameOfPresentedViewInContainerView
                : CGRect(origin: self.presentedView!.frame.origin, size: container.preferredContentSize)
        }
    }
    
}
