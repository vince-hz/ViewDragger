//
//  ViewTravelAnimation.swift
//  ViewTravelAnimation
//
//  Created by xuyunshi on 2023/2/17.
//

import UIKit

public protocol ViewDraggerDelegate: AnyObject {
    func travelAnimationDidStartWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState)

    func travelAnimationDidRecoverWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState)

    func travelAnimationDidUpdateProgress(travelAnimation: ViewDragger, view: UIView, travelState: TravelState, progress: CGFloat)

    func travelAnimationDidCancelWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState)

    func travelAnimationDidCompleteWith(travelAnimation: ViewDragger, view: UIView, travelState: TravelState)
    
    func travelAnimationStartFreeDragging(travelAnimation: ViewDragger, view: UIView)
    
    func travelAnimationFreeDraggingUpdate(travelAnimation: ViewDragger, view: UIView)
    
    func travelAnimationCancelFreeDragging(travelAnimation: ViewDragger, view: UIView)
    
    func travelAnimationEndFreeDragging(travelAnimation: ViewDragger, view: UIView, velocity: CGPoint)
}

public enum AnimationType {
    /// Using `CGAffineTransform`
    case tranform
    /// Using `UIView.frame`
    case frame
}

/// The travel animation direction.
public enum TravelState {
    /// Indicate animation from forwardsSuperView to backwardsSuperView.
    case backwards
    /// Indicate animation from backwardsSuperView to forwardsSuperView.
    case forwards
}

public enum GestureAxis {
    case horizontal
    case vertical
}

public class ViewDragger {
    // MARK: - Public

    public weak var delegate: ViewDraggerDelegate?

    public let panGesture = UIPanGestureRecognizer()

    /// Only enabled when backwardsSuperView and forwardsSuperView was set.
    /// Manually triggered animations.
    /// Only enabled when forwardsView did set.
    public func travel(to travelState: TravelState, animated: Bool = true) {
        if let twoViewDragHandler = dragHandler as? TwoViewDraggerGestureHandler {
            twoViewDragHandler.travel(to: travelState, animated: animated)
        }
    }

    public func updateWithFreeDrag(targetDraggingView: UIView,
                                   animationType: AnimationType? = nil)
    {
        if let animationType {
            self.animationType = animationType
        }
        forwardsSuperView = nil
        self.targetDraggingView = targetDraggingView
        dragHandler = createSuitableDraggerHandler()
    }

    public func updateTwoViewsDrag(backwardsSuperView: UIView,
                                   forwardsSuperView: UIView,
                                   targetDraggingView: UIView?,
                                   backwardsViewFrame: CGRect,
                                   forwardsViewFrame: CGRect,
                                   gestureAxis: GestureAxis,
                                   animationType: AnimationType? = nil,
                                   animatorDuration: TimeInterval? = nil)
    {
        if let animationType {
            self.animationType = animationType
        }
        if let animatorDuration {
            self.animatorDuration = animatorDuration
        }
        self.backwardsSuperView = backwardsSuperView
        self.forwardsSuperView = forwardsSuperView
        self.targetDraggingView = targetDraggingView
        self.backwardsViewFrame = backwardsViewFrame
        self.forwardsViewFrame = forwardsViewFrame
        self.gestureAxis = gestureAxis
        
        dragHandler = createSuitableDraggerHandler()
    }

    private(set) weak var animationView: UIView!
    private(set) weak var backwardsSuperView: UIView!
    private(set) weak var forwardsSuperView: UIView?
    private(set) weak var targetDraggingView: UIView?
    private var backwardsViewFrame: CGRect
    private var forwardsViewFrame: CGRect
    private var gestureAxis: GestureAxis
    private var animationType: AnimationType
    private var animatorDuration: TimeInterval

    private var dragHandler: DraggerGestureHandler? {
        didSet {
            if let oldValue {
                oldValue.destory()
            }
        }
    }

    ///  Free Dragging: Have to set targetDraggingView only.
    ///   - targetDraggingView: specify the common ancestor view instead of fingd by view hierarchy.
    ///   - animationView: view perform animation.
    ///   - targetDraggingView: specify the common ancestor view instead of fingd by view hierarchy.
    ///   - animationType: drag animation type.
    public convenience init(animationView: UIView,
                            targetDraggingView: UIView,
                            animationType: AnimationType = .tranform)
    {
        self.init(animationView,
                  backwardsSuperView: nil,
                  forwardsSuperView: nil,
                  targetDraggingView: targetDraggingView,
                  backwardsViewFrame: .zero,
                  forwardsViewFrame: .zero,
                  gestureAxis: .vertical,
                  animatorDuration: 0,
                  animationType: animationType)
    }

    ///  Dragging between two views:  Have to set backwardsSuperView, forwardsSuperView and gestureAxis.
    /// - Parameters:
    ///   - animationView: view perform animation.
    ///   - backwardsSuperView: backwards animationView's superView.
    ///   - forwardSuperView: forwards animationView's superView.
    ///   - targetDraggingView: specify the common ancestor view instead of fingd by view hierarchy.
    ///   - backwardsViewFrame: animationView frame in backwardsSuperView.
    ///   - forwardsViewFrame: animationView frame in forwardsSuperView.
    ///   - gestureAxis: indicate the panGesture's animation axis.
    ///   - animatorDuration: total duration of the animation.
    ///   - animationType: drag animation type.
    public convenience init(animationView: UIView,
                            backwardsSuperView: UIView,
                            forwardsSuperView: UIView,
                            targetDraggingView: UIView?,
                            backwardsViewFrame: CGRect,
                            forwardsViewFrame: CGRect,
                            gestureAxis: GestureAxis,
                            animatorDuration: TimeInterval = 0.5,
                            animationType: AnimationType = .tranform)
    {
        self.init(animationView,
                  backwardsSuperView: backwardsSuperView,
                  forwardsSuperView: forwardsSuperView,
                  targetDraggingView: targetDraggingView,
                  backwardsViewFrame: backwardsViewFrame,
                  forwardsViewFrame: forwardsViewFrame,
                  gestureAxis: gestureAxis,
                  animatorDuration: animatorDuration,
                  animationType: animationType)
    }

    init(_ animationView: UIView,
         backwardsSuperView: UIView?,
         forwardsSuperView: UIView?,
         targetDraggingView: UIView?,
         backwardsViewFrame: CGRect,
         forwardsViewFrame: CGRect,
         gestureAxis: GestureAxis,
         animatorDuration: TimeInterval,
         animationType: AnimationType)
    {
        self.animationView = animationView
        self.backwardsSuperView = backwardsSuperView
        self.forwardsSuperView = forwardsSuperView
        self.backwardsViewFrame = backwardsViewFrame
        self.forwardsViewFrame = forwardsViewFrame
        self.gestureAxis = gestureAxis
        self.animatorDuration = animatorDuration
        self.animationType = animationType
        self.targetDraggingView = targetDraggingView

        dragHandler = createSuitableDraggerHandler()

        // Setup
        animationView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(onPan))
    }

    func createSuitableDraggerHandler() -> DraggerGestureHandler? {
        if let forwardsSuperView {
            return TwoViewDraggerGestureHandler(animationView: animationView,
                                                backwardsSuperView: backwardsSuperView,
                                                forwardsSuperView: forwardsSuperView,
                                                targetDraggingView: targetDraggingView,
                                                backwardsViewFrame: backwardsViewFrame,
                                                forwardsViewFrame: forwardsViewFrame,
                                                gestureAxis: gestureAxis,
                                                animationType: animationType,
                                                animator: UIViewPropertyAnimator(duration: animatorDuration, curve: .linear),
                                                ref: self)
        } else if let targetDraggingView {
            return FreeViewDraggerGestureHandler(animationView: animationView,
                                                 targetDraggingView: targetDraggingView,
                                                 animationType: animationType,
                                                 ref: self)
        }
        return nil
    }

    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        dragHandler?.onPan(gesture)
    }
}
