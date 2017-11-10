//
//  TrackBarView.swift
//  AVP
//
//  Created by Sergey Chehuta on 09/11/2017.
//  Copyright © 2017 WhiteTown. All rights reserved.
//

import UIKit

class TrackBarView: UIView {

    let slider = UISlider()
    let contentView = UIView()

    public var sliderCallback  : ((_ value : Int64)->Void)?

    private var totalLength : CGFloat = 0

    private var dataString : String? = nil {
        didSet {
            parseString()
        }
    }

    private var data     = [CGPoint]() {
        didSet {
            removeSegments()
            createSegments()
        }
    }

    private var segments = [UIView]()

    public func setString(_ string :String, total : Double)
    {
        if !total.isNaN {
            totalLength = CGFloat(total)
        } else {
            totalLength = 0
        }
        dataString  = string;
    }

    public func setSliderValue(_ value : Float) -> Bool
    {
        if self.slider.isTracking { return false }
        self.slider.value = value

        if isFragmentFinished(Int64(value)) {
            let start = getNearestFragment(Int64(value) - 1)
            sliderCallback?(start)
        }

        return true
    }

    public func getFirstFragment() -> Int64
    {
        if let item = data.first {
            return Int64(item.x)
        }
        return 0
    }

    public func getNearestFragment(_ value : Int64) -> Int64
    {
        for item in data
        {
            if value < Int64(item.x + item.y) {
                return Int64(item.x)
            }
        }

        return value
    }

    func isFragmentFinished(_ value : Int64) -> Bool
    {
        for item in data
        {
            if value == Int64(item.x + item.y) {
                return true
            }
        }

        return false
    }

    func parseString()
    {
        if let trimmed = dataString?.components(separatedBy: CharacterSet.whitespacesAndNewlines).joined(separator: "") {

            let replaceMiddle = trimmed.replacingOccurrences(of: "),(", with: " ")
            let replacePrefix = replaceMiddle.replacingOccurrences(of: "[(", with: "")
            let replaceSuffix = replacePrefix.replacingOccurrences(of: ")]", with: "")

            data = replaceSuffix
                .components(separatedBy: " ")
                .map { CGPointFromString("{\($0)}") }
        }
    }

    func removeSegments()
    {
        slider.removeFromSuperview()
        for subview in segments {
            subview.removeFromSuperview()
        }
        segments.removeAll()
    }

    func createSegments()
    {
        if totalLength == 0
        {
            for item in data
            {
                totalLength = max(totalLength, item.x + item.y + 10)
            }
        }
        if totalLength == 0 { return }

        for item in data
        {
            var frame : CGRect = .zero

            frame.origin.x    = item.x / totalLength * contentView.frame.size.width
            frame.size.width  = item.y / totalLength * contentView.frame.size.width
            frame.size.height = self.frame.size.height

            let segment = UIView(frame: frame)
            segment.autoresizingMask = [ .flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin ]
            segment.backgroundColor  = .green

            segments.append(segment)
            contentView.addSubview(segment)
        }

        slider.maximumValue = Float(totalLength)
        slider.value = 0

        slider.frame = self.bounds
        self.addSubview(slider)
    }

    @objc func sliderMoved(sender : Any?)
    {
        sliderCallback?(getNearestFragment(Int64(self.slider.value)))
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }

//    override func awakeFromNib()
//    {
//        super.awakeFromNib()
//        setup()
//    }

    func setup()
    {
        var frame = self.bounds
        frame.origin.x    = 25.0/2
        frame.size.width -= 25.0
        contentView.frame = frame
        contentView.autoresizingMask = [ .flexibleWidth ]
//        contentView.backgroundColor = .yellow
        self.addSubview(contentView)

        slider.thumbTintColor = .red
        slider.setThumbImage(UIImage(named: "plus"), for: .normal)
        slider.setThumbImage(UIImage(named: "plus"), for: .highlighted)
        slider.setThumbImage(UIImage(named: "plus"), for: .selected)
        slider.isContinuous = false
        slider.autoresizingMask = [ .flexibleWidth ]
        slider.addTarget(self, action: #selector(sliderMoved), for: .valueChanged)
    }

}
