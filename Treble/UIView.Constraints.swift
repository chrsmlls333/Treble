//
//  UIView.Constraints.swift
//  Treble
//
//  Created by Andy Liang on 2016-02-06.
//  Copyright © 2016 Andy Liang. All Rights Reserved. MIT License.
//
//  Modified by Chris Eugene Mills for the Vancouver Art Gallery, April 2018
//

import UIKit

extension UIView {
    
    func constrain(to view: UIView) {
        NSLayoutConstraint.activate(self.leading == view.leading,
                                    self.trailing == view.trailing,
                                    self.top == view.top,
                                    self.bottom == view.bottom)
    }
    
    func constrainSize(to value: CGFloat) {
        NSLayoutConstraint.activate(self.width == value, self.height == value)
    }
}

protocol Axis {}
struct X: Axis {}
struct Y: Axis {}
struct Length: Axis {}

struct LayoutItem<Axis> {
    
    var item: Any
    var attribute: NSLayoutAttribute
    var constant: CGFloat
    var multiplier: CGFloat
    
    init(item: Any, attribute: NSLayoutAttribute, times multiplier: CGFloat, plus constant: CGFloat) {
        self.item = item
        self.attribute = attribute
        self.multiplier = multiplier
        self.constant = constant
    }
    
    fileprivate func constrain(to secondItem: LayoutItem, relation: NSLayoutRelation) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation, toItem: secondItem.item, attribute: secondItem.attribute, multiplier: secondItem.multiplier, constant: secondItem.constant)
    }
    
    fileprivate func constrain(to constant: CGFloat, relation: NSLayoutRelation) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: constant)
    }
    
    fileprivate func layoutItem(times multiplier: CGFloat) -> LayoutItem {
        return LayoutItem(item: self.item, attribute: self.attribute, times: multiplier, plus: self.constant)
    }
    
    fileprivate func layoutItem(plus constant: CGFloat) -> LayoutItem {
        return LayoutItem(item: self.item, attribute: self.attribute, times: self.multiplier, plus: constant)
    }
    
}

func *<T>(lhs: LayoutItem<T>, rhs: CGFloat) -> LayoutItem<T> {
    return lhs.layoutItem(times: lhs.multiplier * rhs)
}

func /<T>(lhs: LayoutItem<T>, rhs: CGFloat) -> LayoutItem<T> {
    return lhs.layoutItem(times: lhs.multiplier / rhs)
}

func +<T>(lhs: LayoutItem<T>, rhs: CGFloat) -> LayoutItem<T> {
    return lhs.layoutItem(plus: lhs.constant + rhs)
}

func -<T>(lhs: LayoutItem<T>, rhs: CGFloat) -> LayoutItem<T> {
    return lhs.layoutItem(plus: lhs.constant - rhs)
}

func ==<T>(lhs: LayoutItem<T>, rhs: LayoutItem<T>) -> NSLayoutConstraint {
    return lhs.constrain(to: rhs, relation: .equal)
}

func ==(lhs: LayoutItem<Length>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.constrain(to: rhs, relation: .equal)
}

func >=<T>(lhs: LayoutItem<T>, rhs: LayoutItem<T>) -> NSLayoutConstraint {
    return lhs.constrain(to: rhs, relation: .greaterThanOrEqual)
}

func >=(lhs: LayoutItem<Length>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.constrain(to: rhs, relation: .greaterThanOrEqual)
}

func <=<T>(lhs: LayoutItem<T>, rhs: LayoutItem<T>) -> NSLayoutConstraint {
    return lhs.constrain(to: rhs, relation: .lessThanOrEqual)
}

func <=(lhs: LayoutItem<Length>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.constrain(to: rhs, relation: .lessThanOrEqual)
}

extension UIView {
    
    var centerX: LayoutItem<X> {
        return self.layoutItem(for: .centerX)
    }
    var centerY: LayoutItem<Y> {
        return self.layoutItem(for: .centerY)
    }
    var left: LayoutItem<X> {
        return self.layoutItem(for: .left)
    }
    var right: LayoutItem<X> {
        return self.layoutItem(for: .right)
    }
    var top: LayoutItem<Y> {
        return self.layoutItem(for: .top)
    }
    var bottom: LayoutItem<Y> {
        return self.layoutItem(for: .bottom)
    }
    var leading: LayoutItem<X> {
        return self.layoutItem(for: .leading)
    }
    var trailing: LayoutItem<X> {
        return self.layoutItem(for: .trailing)
    }
    var width: LayoutItem<Length> {
        return self.layoutItem(for: .width)
    }
    var height: LayoutItem<Length> {
        return self.layoutItem(for: .height)
    }
    var firstBaseline: LayoutItem<Y> {
        return self.layoutItem(for: .firstBaseline)
    }
    var lastBaseline: LayoutItem<Y> {
        return self.layoutItem(for: .lastBaseline)
    }
    var leftMargin: LayoutItem<X> {
        return self.layoutItem(for: .leftMargin)
    }
    var rightMargin: LayoutItem<X> {
        return self.layoutItem(for: .rightMargin)
    }
    var topMargin: LayoutItem<Y> {
        return self.layoutItem(for: .topMargin)
    }
    var bottomMargin: LayoutItem<Y> {
        return self.layoutItem(for: .bottomMargin)
    }
    var leadingMargin: LayoutItem<X> {
        return self.layoutItem(for: .leadingMargin)
    }
    var trailingMargin: LayoutItem<X> {
        return self.layoutItem(for: .trailingMargin)
    }
    var centerXWithinMargins: LayoutItem<X> {
        return self.layoutItem(for: .centerXWithinMargins)
    }
    var centerYWithinMargins: LayoutItem<Y> {
        return self.layoutItem(for: .centerYWithinMargins)
    }
    
    private func layoutItem<T>(for attribute: NSLayoutAttribute) -> LayoutItem<T> {
        return LayoutItem(item: self, attribute: attribute, times: 1.0, plus: 0.0)
    }
    
}

infix operator ~ : LogicalConjunctionPrecedence

func ~(lhs: NSLayoutConstraint, rhs: UILayoutPriority) -> NSLayoutConstraint {
    let newConstraint = NSLayoutConstraint(item: lhs.firstItem!, attribute: lhs.firstAttribute, relatedBy: lhs.relation, toItem: lhs.secondItem!, attribute: lhs.secondAttribute, multiplier: lhs.multiplier, constant: lhs.constant)
    newConstraint.priority = rhs
    return newConstraint
}

extension NSLayoutConstraint {
    
    @discardableResult
    func activate() -> Self {
        self.isActive = true
        return self
    }
    
    @discardableResult
    func deactivate() -> Self {
        self.isActive = false
        return self
    }
    
    static func activate(_ constraints: [NSLayoutConstraint]) {
        constraints.forEach { $0.isActive = true }
    }
    
    static func activate(_ constraints: NSLayoutConstraint...) {
        constraints.forEach { $0.isActive = true }
    }
    
    static func deactivate(_ constraints: [NSLayoutConstraint]) {
        constraints.forEach { $0.isActive = false }
    }
    
    static func deactivate(_ constraints: NSLayoutConstraint...) {
        constraints.forEach { $0.isActive = false }
    }
    
}
