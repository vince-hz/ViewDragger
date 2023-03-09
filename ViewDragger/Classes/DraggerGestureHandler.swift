//
//  DraggerGestureHandler.swift
//  ViewDragger
//
//  Created by xuyunshi on 2023/2/28.
//

import Foundation

protocol DraggerGestureHandler {
    func onPan(_ gesture: UIPanGestureRecognizer)
    func destory()
}
