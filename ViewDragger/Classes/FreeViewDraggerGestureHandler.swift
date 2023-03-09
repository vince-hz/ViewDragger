//
//  FreeViewDraggerGestureHandler.swift
//  ViewDragger
//
//  Created by xuyunshi on 2023/2/28.
//

import Foundation

class FreeViewDraggerGestureHandler: DraggerGestureHandler {
    internal init(animationView: UIView?,
                  targetDraggingView: UIView?,
                  animationType: AnimationType,
                  ref: ViewDragger?)
    {
        self.animationView = animationView
        self.targetDraggingView = targetDraggingView
        self.ref = ref
        self.animationType = animationType
    }

    weak var animationView: UIView!
    weak var targetDraggingView: UIView!
    weak var ref: ViewDragger!
    var animationType: AnimationType
    var lastPoint = CGPoint.zero
    var beginDragFrame = CGRect.zero

    func destory() {
        
    }
    
    func onPan(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.translation(in: targetDraggingView)
        defer {
            lastPoint = currentPoint
        }
        switch gesture.state {
        case .began:
            if animationView.superview != targetDraggingView {
                let startFrame = animationView.frame
                if let startFrameInDraggingView = animationView.superview?.convert(startFrame, to: targetDraggingView) {
                    targetDraggingView.addSubview(animationView)
                    animationView.frame = startFrameInDraggingView
                    beginDragFrame = startFrameInDraggingView
                }
            }
            ref.delegate?.travelAnimationStartFreeDragging(travelAnimation: ref, view: animationView)
        case .changed:
            switch animationType {
            case .tranform:
                let delta = CGPoint(x: currentPoint.x - lastPoint.x, y: currentPoint.y - lastPoint.y)
                animationView.transform = .init(translationX: animationView.transform.tx + delta.x,
                                                y: animationView.transform.ty + delta.y)
            case .frame:
                var frame = animationView.frame
                let delta = CGPoint(x: currentPoint.x - lastPoint.x, y: currentPoint.y - lastPoint.y)
                frame = CGRect(x: frame.origin.x + delta.x,
                               y: frame.origin.y + delta.y,
                               width: frame.width,
                               height: frame.height)
                animationView.frame = frame
            }
            ref.delegate?.travelAnimationFreeDraggingUpdate(travelAnimation: ref, view: animationView)
        case .cancelled:
            cancelDragging()
        case .ended:
            finishDragging(velocity: gesture.velocity(in: targetDraggingView))
        default:
            return
        }
    }
    
    func cancelDragging() {
        switch animationType {
        case .tranform:
            animationView.transform = .identity
        case .frame:
            animationView.frame = beginDragFrame
        }
        ref.delegate?.travelAnimationCancelFreeDragging(travelAnimation: ref, view: animationView)
    }
    
    func finishDragging(velocity: CGPoint) {
        switch animationType {
        case .tranform:
            var frame = animationView.frame
            frame.origin.x += animationView.transform.tx
            frame.origin.y += animationView.transform.ty
            animationView.frame = frame
            animationView.transform = .identity
        case .frame:
            break
        }
        ref.delegate?.travelAnimationEndFreeDragging(travelAnimation: ref, view: animationView, velocity: velocity)
    }
}
