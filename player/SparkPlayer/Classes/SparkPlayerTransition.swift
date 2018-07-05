//
//  SparkPlayerTransition.swift
//  SparkPlayer
//
//  Created by norlin on 05/04/2018.
//

import Foundation

protocol SparkPlayerTransitionDelegate {
    func didFullscreenAppear()
    func didFullscreenDismissed()
}

extension SparkPlayer: SparkPlayerTransitionDelegate {
    func didFullscreenAppear() {
        fullscreenController.isFullscreen = true
    }

    func didFullscreenDismissed() {
        onTransitionEnded()
    }
}

extension SparkPlayer: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        let origin = inlineController.view.convert(inlineController.view.frame.origin, to: inlineController.view.window!.screen.fixedCoordinateSpace)
        inlineFrame = CGRect(origin: origin, size: inlineController.view.frame.size)
        return FullscreenRotationAnimator(originFrame: inlineFrame!, delegate: self)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        let originFrame: CGRect
        if let inlineFrame = self.inlineFrame {
            originFrame = inlineFrame
        } else {
            originFrame = CGRect(origin: CGPoint.zero, size: inlineController.view.frame.size)
        }

        return FullscreenRotationDismissAnimator(originFrame: originFrame, delegate: self)
    }
}
