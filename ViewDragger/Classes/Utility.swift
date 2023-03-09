//
//  Utility.swift
//  ViewDragger
//
//  Created by xuyunshi on 2023/2/27.
//

import Foundation

// Calc center translate
func getTravelUnit(
    forwardsSuperView: UIView,
    forwardsViewFrame: CGRect,
    backwardsSuperView: UIView,
    backwardsViewFrame: CGRect,
    commonAncestorView: UIView,
    travelState: TravelState,
    axis: GestureAxis
) -> CGFloat {
    let travelUnit: CGFloat
    switch axis {
    case .horizontal:
        let forwardsXInWindow = forwardsSuperView.convert(CGPoint(x: forwardsViewFrame.origin.x + forwardsViewFrame.width / 2,
                                                                  y: 0),
                                                          to: commonAncestorView).x
        let backwardsXInWindow = backwardsSuperView.convert(CGPoint(x: backwardsViewFrame.origin.x + backwardsViewFrame.width / 2,
                                                                    y: 0),
                                                            to: commonAncestorView).x
        switch travelState {
        case .backwards:
            travelUnit = backwardsXInWindow - forwardsXInWindow
        case .forwards:
            travelUnit = forwardsXInWindow - backwardsXInWindow
        }
    case .vertical:
        let forwardsYInWindow = forwardsSuperView.convert(CGPoint(x: 0,
                                                                  y: forwardsViewFrame.origin.y + forwardsViewFrame.height / 2),
                                                          to: commonAncestorView).y
        let backwardsYInWindow = backwardsSuperView.convert(CGPoint(x: 0,
                                                                    y: backwardsViewFrame.origin.y + backwardsViewFrame.height / 2),
                                                            to: commonAncestorView).y
        switch travelState {
        case .backwards:
            travelUnit = backwardsYInWindow - forwardsYInWindow
        case .forwards:
            travelUnit = forwardsYInWindow - backwardsYInWindow
        }
    }
    return travelUnit
}

// Calc transform
func getTransform(
    forwardsSuperView: UIView,
    forwardsViewFrame: CGRect,
    backwardsSuperView: UIView,
    backwardsViewFrame: CGRect,
    commonAncestorView: UIView,
    travelState: TravelState,
    currentFrameInAncestorView: CGRect
) -> CGAffineTransform {
    let startFrameInAncestor = currentFrameInAncestorView
    let transform: CGAffineTransform
    switch travelState {
    case .backwards:
        let toFrameInWindow = backwardsSuperView.convert(backwardsViewFrame, to: commonAncestorView)
        let fromCenter = startFrameInAncestor.origin.applying(.init(translationX: startFrameInAncestor.width / 2, y: startFrameInAncestor.height / 2))
        let toCenter = toFrameInWindow.origin.applying(.init(translationX: toFrameInWindow.width / 2, y: toFrameInWindow.height / 2))
        transform = CGAffineTransform(
            translationX: toCenter.x - fromCenter.x,
            y: toCenter.y - fromCenter.y
        ).scaledBy(
            x: toFrameInWindow.size.width / startFrameInAncestor.size.width,
            y: toFrameInWindow.size.height / startFrameInAncestor.size.height
        )
    case .forwards:
        let toFrameInWindow = forwardsSuperView.convert(forwardsViewFrame, to: commonAncestorView)
        let fromCenter = startFrameInAncestor.origin.applying(.init(translationX: startFrameInAncestor.width / 2, y: startFrameInAncestor.height / 2))
        let toCenter = toFrameInWindow.origin.applying(.init(translationX: toFrameInWindow.width / 2, y: toFrameInWindow.height / 2))
        transform = CGAffineTransform(
            translationX: toCenter.x - fromCenter.x,
            y: toCenter.y - fromCenter.y
        ).scaledBy(
            x: toFrameInWindow.size.width / startFrameInAncestor.size.width,

            y: toFrameInWindow.size.height / startFrameInAncestor.size.height
        )
    }
    return transform
}

func getCommonAncestor(
    _ a: UIView,
    _ b: UIView
) -> UIView? {
    var target: UIView? = a
    while let obj = target {
        if b.isDescendant(of: obj), !(obj is UIStackView) {
            return obj
        }
        target = obj.superview
    }
    return nil
}

func safeProgress(_ p: CGFloat) -> CGFloat {
    min(1, max(0, p))
}
