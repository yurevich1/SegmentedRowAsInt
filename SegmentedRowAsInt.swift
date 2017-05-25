//
//  SegmentedCellAsInt.swift
//  horoscope
//
//  Created by Vyacheslav Petrukhin on 23.09.16.
//  Copyright © 2016 PS. All rights reserved.
//


import Foundation
import Eureka


open class SegmentedCellAsInt<T: Equatable> : Cell<Int>, CellType {
    
    open var titleLabel : UILabel? {
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        textLabel?.setContentHuggingPriority(500, for: .horizontal)
        return textLabel
    }
    lazy open var segmentedControl : UISegmentedControl = {
        let result = UISegmentedControl()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.setContentHuggingPriority(250, for: .horizontal)
        return result
    }()
    fileprivate var dynamicConstraints = [NSLayoutConstraint]()
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        segmentedControl.removeTarget(self, action: nil, for: .allEvents)
        titleLabel?.removeObserver(self, forKeyPath: "text")
        imageView?.removeObserver(self, forKeyPath: "image")
    }
    
    open override func setup() {
        super.setup()
        height = { BaseRow.estimatedRowHeight }
        selectionStyle = .none
        contentView.addSubview(titleLabel!)
        contentView.addSubview(segmentedControl)
        titleLabel?.addObserver(self, forKeyPath: "text", options: [.old, .new], context: nil)
        imageView?.addObserver(self, forKeyPath: "image", options: [.old, .new], context: nil)
        segmentedControl.addTarget(self, action: #selector(SegmentedCellAsInt.valueChanged), for: .valueChanged)
        contentView.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    open override func update() {
        super.update()
        detailTextLabel?.text = nil
        
        updateSegmentedControl()
        segmentedControl.selectedSegmentIndex = selectedIndex() ?? UISegmentedControlNoSegment
        segmentedControl.isEnabled = !row.isDisabled
        
        if row.isHighlighted {
            textLabel?.textColor = tintColor
        }
    }
    
    func valueChanged() {
        row.value = segmentedControl.selectedSegmentIndex
    }
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let obj = object as AnyObject?
        
        if let changeType = change, let _ = keyPath, ((obj === titleLabel && keyPath == "text") || (obj === imageView && keyPath == "image")) && (changeType[NSKeyValueChangeKey.kindKey] as? NSNumber)?.uintValue == NSKeyValueChange.setting.rawValue{
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }
    
    
    func updateSegmentedControl() {
        segmentedControl.removeAllSegments()
        items().enumerated().forEach { segmentedControl.insertSegment(withTitle: $0.element, at: $0.offset, animated: false) }
    }
    
    open override func updateConstraints() {
        contentView.removeConstraints(dynamicConstraints)
        dynamicConstraints = []
        var views : [String: AnyObject] =  ["segmentedControl": segmentedControl]
        
        var hasImageView = false
        var hasTitleLabel = false
        
        if let imageView = imageView, let _ = imageView.image {
            views["imageView"] = imageView
            hasImageView = true
        }
        
        if let titleLabel = titleLabel, let text = titleLabel.text , !text.isEmpty {
            views["titleLabel"] = titleLabel
            hasTitleLabel = true
            dynamicConstraints.append(NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0))
        }
        
        dynamicConstraints.append(NSLayoutConstraint(item: segmentedControl, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: 0.3, constant: 0.0))
        
        
        if hasImageView && hasTitleLabel {
            dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-[titleLabel]-[segmentedControl]-|", options: [], metrics: nil, views: views)
        }
        else if hasImageView && !hasTitleLabel {
            dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-[segmentedControl]-|", options: [], metrics: nil, views: views)
        }
        else if !hasImageView && hasTitleLabel {
            dynamicConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-[segmentedControl]-|", options: .alignAllCenterY, metrics: nil, views: views)
        }
        else {
            dynamicConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[segmentedControl]-|", options: .alignAllCenterY, metrics: nil, views: views)
        }
        contentView.addConstraints(dynamicConstraints)
        super.updateConstraints()
    }
    func getNames() -> [String] {
        return ((row as! SegmentedRowAsInt).names) ?? []
    }
    func items() -> [String] {
        var result = [String]()
        for i in 0..<getNames().count {
            result.append(row.displayValueFor?(i) ?? "")
        }

        return result
    }
    
    func selectedIndex() -> Int? {
        guard let value = row.value else { return nil }
        return value
    }
}

//MARK: SegmentedRowAsInt

/// An options row where the user can select an option from an UISegmentedControl
public final class SegmentedRowAsInt: OptionsRow<SegmentedCellAsInt<Int>>, RowType {
    
//    public var tag: String?
public var names : [String]?
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value, let n = self.names else { return nil }
            return "\(n[val])"
        }
    }
}

