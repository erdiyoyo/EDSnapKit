//
//  EDSnapKit.swift
//  erdi
//
//  Created by erdi on 2025/5/23.
//

import UIKit

// MARK: - UIView + snp
public extension UIView {
    var snp: ConstraintViewDSL { ConstraintViewDSL(view: self) }
}

// MARK: - DSL 入口
public class ConstraintViewDSL {
    weak var view: UIView?
    init(view: UIView) { self.view = view }
    
    @discardableResult
    public func makeConstraints(_ closure: (ConstraintMaker) -> Void) -> [NSLayoutConstraint] {
        guard let view = view else { return [] }
        view.translatesAutoresizingMaskIntoConstraints = false
        let maker = ConstraintMaker(view: view)
        closure(maker)
        return maker.install()
    }
    
    @discardableResult
    public func remakeConstraints(_ closure: (ConstraintMaker) -> Void) -> [NSLayoutConstraint] {
        view?.removeConstraints(view?.constraints ?? [])
        return makeConstraints(closure)
    }
    
    @discardableResult
    public func updateConstraints(_ closure: (ConstraintMaker) -> Void) -> [NSLayoutConstraint] {
        return makeConstraints(closure)
    }
}

// MARK: - 约束构造器
public class ConstraintMaker {
    weak var view: UIView?
    var constraints: [NSLayoutConstraint] = []
    var pendingItems: [ConstraintItem] = []
    
    init(view: UIView) { self.view = view }
    
    public var top: ConstraintItem { item(.top) }
    public var bottom: ConstraintItem { item(.bottom) }
    public var left: ConstraintItem { item(.left) }
    public var right: ConstraintItem { item(.right) }
    public var leading: ConstraintItem { item(.leading) }
    public var trailing: ConstraintItem { item(.trailing) }
    public var centerX: ConstraintItem { item(.centerX) }
    public var centerY: ConstraintItem { item(.centerY) }
    public var width: ConstraintItem { item(.width) }
    public var height: ConstraintItem { item(.height) }
    
    public var edges: ConstraintEdges { ConstraintEdges(maker: self) }
    public var size: ConstraintSize { ConstraintSize(maker: self) }
    public var center: ConstraintCenter { ConstraintCenter(maker: self) }
    
    private func item(_ attr: NSLayoutConstraint.Attribute) -> ConstraintItem {
        let i = ConstraintItem(view: view, attribute: attr)
        pendingItems.append(i)
        return i
    }
    
    func install() -> [NSLayoutConstraint] {
        guard let view = view else { return [] }
        for item in pendingItems {
            let constraint: NSLayoutConstraint
            if item.attribute == .width || item.attribute == .height, item.targetView == nil {
                constraint = NSLayoutConstraint(item: view, attribute: item.attribute,
                                                relatedBy: item.relation,
                                                toItem: nil, attribute: .notAnAttribute,
                                                multiplier: item.multiplier, constant: item.constant)
            } else {
                let toItem = item.targetView ?? view.superview!
                let toAttr = item.targetAttr ?? item.attribute
                constraint = NSLayoutConstraint(item: view, attribute: item.attribute,
                                                relatedBy: item.relation,
                                                toItem: toItem, attribute: toAttr,
                                                multiplier: item.multiplier, constant: item.constant)
            }
            constraint.priority = item.priority
            constraints.append(constraint)
        }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}

// MARK: - 单个约束元素
public class ConstraintItem {
    weak var view: UIView?
    let attribute: NSLayoutConstraint.Attribute
    var relation: NSLayoutConstraint.Relation = .equal
    var targetView: UIView?
    var targetAttr: NSLayoutConstraint.Attribute?
    var constant: CGFloat = 0
    var multiplier: CGFloat = 1
    var priority: UILayoutPriority = .required
    
    init(view: UIView?, attribute: NSLayoutConstraint.Attribute) {
        self.view = view
        self.attribute = attribute
    }
    
    public func equalToSuperview() -> Self {
        self.targetView = view?.superview
        self.targetAttr = attribute
        return self
    }
    
    public func equalTo(_ other: Any) -> Self {
        if let v = other as? UIView {
            self.targetView = v
            self.targetAttr = attribute
        } else if let num = other as? CGFloat {
            self.targetView = nil
            self.constant = num
        }
        return self
    }
    
    public func lessThanOrEqualTo(_ other: Any) -> Self {
        relation = .lessThanOrEqual
        return equalTo(other)
    }
    
    public func greaterThanOrEqualTo(_ other: Any) -> Self {
        relation = .greaterThanOrEqual
        return equalTo(other)
    }
    
    public func offset(_ value: CGFloat) -> Self {
        self.constant = value
        return self
    }
    
    public func inset(_ value: CGFloat) -> Self {
        if attribute == .right || attribute == .bottom || attribute == .trailing {
            self.constant = -value
        } else {
            self.constant = value
        }
        return self
    }
    
    public func multipliedBy(_ value: CGFloat) -> Self {
        self.multiplier = value
        return self
    }
    
    public func priority(_ value: UILayoutPriority) -> Self {
        self.priority = value
        return self
    }
}

// MARK: - edges / size / center
public class ConstraintEdges {
    weak var maker: ConstraintMaker?
    init(maker: ConstraintMaker?) { self.maker = maker }
    
    public func equalToSuperview() {
        maker?.top.equalToSuperview()
        maker?.left.equalToSuperview()
        maker?.right.equalToSuperview()
        maker?.bottom.equalToSuperview()
    }
    
    public func inset(_ value: CGFloat) {
        maker?.top.inset(value).equalToSuperview()
        maker?.left.inset(value).equalToSuperview()
        maker?.right.inset(value).equalToSuperview()
        maker?.bottom.inset(value).equalToSuperview()
    }
}

public class ConstraintSize {
    weak var maker: ConstraintMaker?
    init(maker: ConstraintMaker?) { self.maker = maker }
    
    public func equalTo(_ size: CGSize) {
        maker?.width.equalTo(size.width)
        maker?.height.equalTo(size.height)
    }
}

public class ConstraintCenter {
    weak var maker: ConstraintMaker?
    init(maker: ConstraintMaker?) { self.maker = maker }
    
    public func equalToSuperview() {
        maker?.centerX.equalToSuperview()
        maker?.centerY.equalToSuperview()
    }
}
