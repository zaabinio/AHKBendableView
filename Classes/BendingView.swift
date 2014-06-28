//
//  BendingView.swift
//  AHKBendingView
//
//  Created by Arkadiusz on 26-06-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

import UIKit
import CoreGraphics
import QuartzCore

class BendingLayer: CALayer {

    override func addAnimation(anim: CAAnimation!, forKey key: String!) {
        super.addAnimation(anim, forKey: key)

        if let basicAnimation = anim as? CABasicAnimation {
            if basicAnimation.keyPath == NSStringFromSelector("position") {
                self.delegate?.positionAnimationWillStart?(basicAnimation)
            }
        }
    }
}

protocol BendingLayerDelegate {
    func positionAnimationWillStart(anim: CABasicAnimation)
}

class BendingView: UIView, BendingLayerDelegate {

    // MARK: Public properties

    var damping: CGFloat = 0.7
    var initialSpringVelocity: CGFloat = 0.8
    var fillColor = UIColor(red: 0, green: 0.722, blue: 1, alpha: 1) // blue color

    // MARK: Private properties

    var displayLink: CADisplayLink?
    var animationCount = 0
    let dummyView = UIView()
    let shapeLayer = CAShapeLayer()

    var bendingFactor: CGPoint = CGPointZero {
        didSet {
            updatePath()
        }
    }

    var path: UIBezierPath {
        get {
            var frame: CGRect
            if let presentationLayer = layer.presentationLayer() as? CALayer {
                frame = presentationLayer.frame
            } else {
                frame = self.frame
            }
            let width = CGRectGetWidth(frame)
            let height = CGRectGetHeight(frame)

            let path = UIBezierPath()
            path.moveToPoint(CGPoint(x: 0, y: 0))
            path.addQuadCurveToPoint(CGPoint(x: width, y: 0),
                controlPoint:CGPoint(x: width / 2.0, y: 0 + bendingFactor.y))
            path.addQuadCurveToPoint(CGPoint(x: width, y: height),
                controlPoint:CGPoint(x: width + bendingFactor.x, y: height / 2.0))
            path.addQuadCurveToPoint(CGPoint(x: 0, y: height),
                controlPoint: CGPoint(x: width / 2.0, y: height + bendingFactor.y))
            path.addQuadCurveToPoint(CGPoint(x: 0, y: 0),
                controlPoint: CGPoint(x: bendingFactor.x, y: height / 2.0))
            path.closePath()

            return path
        }
    }

    // MARK: Init

    init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)

        commonInit()
    }

    func commonInit() {
        shapeLayer.fillColor = fillColor.CGColor
        self.layer.insertSublayer(shapeLayer, atIndex: 0)
        updatePath()

        addSubview(dummyView)
    }

    // MARK: UIView

    override class func layerClass() -> AnyClass {
        return BendingLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updatePath()

        dummyView.frame.origin = frame.origin
    }

    // MARK: BendingLayerDelegate

    func positionAnimationWillStart(anim: CABasicAnimation) {
        if !displayLink {
            displayLink = CADisplayLink(target: self, selector: "tick:")
            displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        }
        animationCount++

        let newPosition = layer.frame.origin

        let verticalDelta = abs(CGRectGetMinY(dummyView.frame) - newPosition.y)
        let horizontalDelta = abs(CGRectGetMinX(dummyView.frame) - newPosition.x)

        UIView.animateWithDuration(anim.duration,
            delay: anim.beginTime,
            usingSpringWithDamping: damping,
            initialSpringVelocity: initialSpringVelocity,
            options: .BeginFromCurrentState | .AllowUserInteraction | .OverrideInheritedOptions,
            animations: {
                self.dummyView.frame.origin = newPosition
            }, completion: { _ in
                self.animationCount--
                if self.animationCount == 0 {
                    self.displayLink!.invalidate()
                    self.displayLink = nil
                }
            }
        )
    }

    // MARK: Private

    func updatePath() {
        shapeLayer.path = path.CGPath
    }

    func tick(displayLink: CADisplayLink) {
        let dummyViewPresentationLayer = dummyView.layer.presentationLayer() as CALayer
        let presentationLayer = layer.presentationLayer() as CALayer

        bendingFactor = CGPoint(x: CGRectGetMinX(dummyViewPresentationLayer.frame) - CGRectGetMinX(presentationLayer.frame),
            y: CGRectGetMinY(dummyViewPresentationLayer.frame) - CGRectGetMinY(presentationLayer.frame))
    }
}