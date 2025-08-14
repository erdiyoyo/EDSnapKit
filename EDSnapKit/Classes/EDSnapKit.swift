//
//  EDSnapKit.swift
//  erdi
//
//  Created by erdi on 2025/5/23.
//

import UIKit

// MARK: - UIView + UILayoutGuide + snp
public extension UIView {
    var snp: ConstraintViewDSL { ConstraintViewDSL(view: self) }
}

public extension UILayoutGuide {
    var snp: ConstraintViewDSL { ConstraintViewDSL(guide: self) }
}

// MARK: - DSL 入口
public class ConstraintViewDSL {
    weak var view: UIView?
    weak var guide: UILayoutGuide?
    
    init(view: UIView) { self.view = view }
    init(guide: UILayoutGuide) { self.guide = guide }
    
    @discardableResult
    public func makeConstraints(_ closure: (ConstraintMaker) -> Void) -> [NSLayoutConstraint] {
        let maker = ConstraintMaker(view: view, guide: guide)
        closure(maker)
        return maker.install()
    }
    
    @discardableResult
    public func remakeConstraints(_ closure: (ConstraintMaker) -> Void) -> [NSLayoutConstraint] {
        if let view = view {
            view.removeConstraints(view.constraints)
        }
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
    weak var guide: UILayoutGuide?
    var constraints: [NSLayoutConstraint] = []
    var pendingItems: [ConstraintItem] = []
    
    init(view: UIView?, guide: UILayoutGuide? = nil) {
        self.view = view
        self.guide = guide
    }
    
    // MARK: - 单点约束
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
        let i = ConstraintItem(view: view, guide: guide, attribute: attr)
        pendingItems.append(i)
        return i
    }
    
    func install() -> [NSLayoutConstraint] {
        var installed: [NSLayoutConstraint] = []
        for item in pendingItems {
            let constraint: NSLayoutConstraint
            if item.attribute == .width || item.attribute == .height, item.targetView == nil, item.targetGuide == nil {
                constraint = NSLayoutConstraint(item: item.viewOrGuide,
                                                attribute: item.attribute,
                                                relatedBy: item.relation,
                                                toItem: nil, attribute: .notAnAttribute,
                                                multiplier: item.multiplier, constant: item.constant)
            } else {
                let toItem: Any = item.targetView ?? item.targetGuide ?? item.viewOrGuide.superview!
                let toAttr = item.targetAttr ?? item.attribute
                constraint = NSLayoutConstraint(item: item.viewOrGuide,
                                                attribute: item.attribute,
                                                relatedBy: item.relation,
                                                toItem: toItem, attribute: toAttr,
                                                multiplier: item.multiplier, constant: item.constant)
            }
            constraint.priority = item.priority
            installed.append(constraint)
        }
        NSLayoutConstraint.activate(installed)
        return installed
    }
}

// MARK: - 单个约束元素
public class ConstraintItem {
    weak var view: UIView?
    weak var guide: UILayoutGuide?
    let attribute: NSLayoutConstraint.Attribute
    
    var relation: NSLayoutConstraint.Relation = .equal
    var targetView: UIView?
    var targetGuide: UILayoutGuide?
    var targetAttr: NSLayoutConstraint.Attribute?
    
    var constant: CGFloat = 0
    var multiplier: CGFloat = 1
    var priority: UILayoutPriority = .required
    
    init(view: UIView?, guide: UILayoutGuide?, attribute: NSLayoutConstraint.Attribute) {
        self.view = view
        self.guide = guide
        self.attribute = attribute
    }
    
    var viewOrGuide: Any {
        return view ?? guide!
    }
    
    @discardableResult
    public func equalTo(_ other: Any) -> Self {
        if let v = other as? UIView {
            targetView = v
            targetAttr = attribute
        } else if let g = other as? UILayoutGuide {
            targetGuide = g
            targetAttr = attribute
        } else if let item = other as? ConstraintItem {
            targetView = item.view
            targetGuide = item.guide
            targetAttr = item.attribute
        } else if let num = other as? CGFloat {
            targetView = nil
            targetGuide = nil
            constant = num
        } else {
            fatalError("equalTo: unsupported type \(type(of: other))")
        }
        return self
    }
    
    @discardableResult
    public func lessThanOrEqualTo(_ other: Any) -> Self {
        relation = .lessThanOrEqual
        return equalTo(other)
    }
    
    @discardableResult
    public func greaterThanOrEqualTo(_ other: Any) -> Self {
        relation = .greaterThanOrEqual
        return equalTo(other)
    }
    
    @discardableResult
    public func offset(_ value: CGFloat) -> Self {
        constant = value
        return self
    }
    
    @discardableResult
    public func inset(_ value: CGFloat) -> Self {
        if attribute == .right || attribute == .bottom || attribute == .trailing {
            constant = -value
        } else {
            constant = value
        }
        return self
    }
    
    @discardableResult
    public func multipliedBy(_ value: CGFloat) -> Self {
        multiplier = value
        return self
    }
    
    @discardableResult
    public func priority(_ value: UILayoutPriority) -> Self {
        priority = value
        return self
    }
}

// MARK: - edges / size / center
public class ConstraintEdges {
    weak var maker: ConstraintMaker?
    init(maker: ConstraintMaker?) { self.maker = maker }
    
    @discardableResult
    public func equalToSuperview() -> Self {
        maker?.top.equalToSuperview()
        maker?.left.equalToSuperview()
        maker?.right.equalToSuperview()
        maker?.bottom.equalToSuperview()
        return self
    }
    
    @discardableResult
    public func inset(_ value: CGFloat) -> Self {
        maker?.top.inset(value).equalToSuperview()
        maker?.left.inset(value).equalToSuperview()
        maker?.right.inset(value).equalToSuperview()
        maker?.bottom.inset(value).equalToSuperview()
        return self
    }
}

public class ConstraintSize {
    weak var maker: ConstraintMaker?
    init(maker: ConstraintMaker?) { self.maker = maker }
    
    @discardableResult
    public func equalTo(_ size: CGSize) -> Self {
        maker?.width.equalTo(size.width)
        maker?.height.equalTo(size.height)
        return self
    }
}

public class ConstraintCenter {
    weak var maker: ConstraintMaker?
    init(maker: ConstraintMaker?) { self.maker = maker }
    
    @discardableResult
    public func equalToSuperview() -> Self {
        maker?.centerX.equalToSuperview()
        maker?.centerY.equalToSuperview()
        return self
    }
    
    @discardableResult
    public func equalTo(_ view: UIView) -> Self {
        maker?.centerX.equalTo(view)
        maker?.centerY.equalTo(view)
        return self
    }
    
    @discardableResult
    public func equalTo(_ guide: UILayoutGuide) -> Self {
        maker?.centerX.equalTo(guide)
        maker?.centerY.equalTo(guide)
        return self
    }
}
