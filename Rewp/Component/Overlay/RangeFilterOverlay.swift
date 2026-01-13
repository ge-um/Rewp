//
//  RangeFilterOverlay.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import UIKit
import PinLayout
import Then
import RxSwift

final class RangeFilterOverlay: UIView {
    var onDismiss: (() -> Void)?

    let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 12
        $0.layer.applyShadow(ShadowSystem.xl)
    }

    private let rangeBubbleView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let bubbleShapeLayer = CAShapeLayer()

    private let rangeLabel = UILabel().then {
        $0.textAlignment = .center
    }

    private let slider = RangeSlider()

    private let minTickContainer = UIView()
    private let minTickView = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }
    private let minLabel = UILabel().then {
        $0.textAlignment = .center
    }

    private let midTickContainer = UIView()
    private let midTickView = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }
    private let midLabel = UILabel().then {
        $0.textAlignment = .center
    }

    private let maxTickContainer = UIView()
    private let maxTickView = UIView().then {
        $0.backgroundColor = ColorSystem.gray30
    }
    private let maxLabel = UILabel().then {
        $0.textAlignment = .center
    }

    private var currentMinValue: Int = 0
    private var currentMaxValue: Int = 100
    private let disposeBag = DisposeBag()

    private var unit: String
    private var minValue: Int
    private var maxValue: Int
    private var minLabelText: String
    private var maxLabelText: String
    private var midLabelText: String?

    func getCurrentRange() -> (min: Int, max: Int) {
        return (min: currentMinValue, max: currentMaxValue)
    }

    init(
        unit: String,
        minValue: Int,
        maxValue: Int,
        minLabelText: String = "최소",
        maxLabelText: String = "최대",
        midLabelText: String? = nil
    ) {
        self.unit = unit
        self.minValue = minValue
        self.maxValue = maxValue
        self.minLabelText = minLabelText
        self.maxLabelText = maxLabelText
        self.midLabelText = midLabelText

        super.init(frame: .zero)
        setupUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(currentMin: Int, currentMax: Int) {
        self.currentMinValue = currentMin
        self.currentMaxValue = currentMax
        slider.configure(min: minValue, max: maxValue, currentMin: currentMin, currentMax: currentMax)
        updateRangeLabel(min: currentMin, max: currentMax)
    }

    func reconfigure(
        unit: String,
        minValue: Int,
        maxValue: Int,
        minLabelText: String,
        maxLabelText: String,
        midLabelText: String?
    ) {
        self.unit = unit
        self.minValue = minValue
        self.maxValue = maxValue
        self.minLabelText = minLabelText
        self.maxLabelText = maxLabelText
        self.midLabelText = midLabelText

        minLabel.typography(FontSystem.Pretendard.caption2, text: minLabelText, textColor: ColorSystem.gray60)
        maxLabel.typography(FontSystem.Pretendard.caption2, text: maxLabelText, textColor: ColorSystem.gray60)

        if let midText = midLabelText {
            if midTickContainer.superview == nil {
                containerView.addSubview(midTickContainer)
                midTickContainer.addSubview(midTickView)
                midTickContainer.addSubview(midLabel)
            }
            midLabel.typography(FontSystem.Pretendard.caption2, text: midText, textColor: ColorSystem.gray60)
            midTickContainer.isHidden = false
        } else {
            midTickContainer.isHidden = true
        }

        setNeedsLayout()
    }

    func isVisible() -> Bool {
        return superview != nil && containerView.alpha > 0
    }

    func show(in parentView: UIView, below sourceView: UIView) {
        parentView.addSubview(self)
        frame = parentView.bounds

        let sourceFrame = sourceView.convert(sourceView.bounds, to: parentView)

        containerView.alpha = 0
        containerView.transform = CGAffineTransform(translationX: 0, y: -10)

        let arrowSize: CGFloat = 8
        let arrowY = sourceFrame.maxY + 5

        let overlayWidth: CGFloat = 350
        let overlayHeight: CGFloat = 85
        let overlayX = (parentView.bounds.width - overlayWidth) / 2
        let overlayY = arrowY + arrowSize

        containerView.frame = CGRect(x: overlayX, y: overlayY, width: overlayWidth, height: overlayHeight)

        self.containerView.alpha = 1
        self.containerView.transform = .identity
    }

    func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: -10)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(containerView)

        containerView.addSubview(rangeBubbleView)
        rangeBubbleView.layer.addSublayer(bubbleShapeLayer)
        rangeBubbleView.addSubview(rangeLabel)
        containerView.addSubview(slider)

        containerView.addSubview(minTickContainer)
        minTickContainer.addSubview(minTickView)
        minTickContainer.addSubview(minLabel)

        if midLabelText != nil {
            containerView.addSubview(midTickContainer)
            midTickContainer.addSubview(midTickView)
            midTickContainer.addSubview(midLabel)
        }

        containerView.addSubview(maxTickContainer)
        maxTickContainer.addSubview(maxTickView)
        maxTickContainer.addSubview(maxLabel)

        minLabel.typography(FontSystem.Pretendard.caption2, text: minLabelText, textColor: ColorSystem.gray60)
        maxLabel.typography(FontSystem.Pretendard.caption2, text: maxLabelText, textColor: ColorSystem.gray60)
        if let midText = midLabelText {
            midLabel.typography(FontSystem.Pretendard.caption2, text: midText, textColor: ColorSystem.gray60)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        addGestureRecognizer(tapGesture)
    }

    private func bind() {
        let output = slider.transform()
        output.rangeChanged
            .withUnretained(self)
            .subscribe(onNext: { owner, range in
                owner.currentMinValue = range.min
                owner.currentMaxValue = range.max
                owner.updateRangeLabel(min: range.min, max: range.max)
            })
            .disposed(by: disposeBag)
    }

    private func updateRangeLabel(min: Int, max: Int) {
        let minText: String
        let maxText: String

        if unit == "만원" {
            minText = min.formatAsManwon()
            maxText = max.formatAsManwon()
        } else {
            minText = "\(min)\(unit)"
            maxText = "\(max)\(unit)"
        }

        rangeLabel.typography(FontSystem.Pretendard.caption1Medium, text: "\(minText) ~ \(maxText)", textColor: ColorSystem.gray60)
        setNeedsLayout()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self {
            return nil
        }

        if !containerView.frame.contains(point) {
            return nil
        }

        return hitView
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if !containerView.frame.contains(location) {
            onDismiss?()
            hide()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rangeLabel.sizeToFit()

        let arrowHeight: CGFloat = 4
        rangeBubbleView.pin
            .top(10)
            .hCenter()
            .width(rangeLabel.frame.width + 16)
            .height(rangeLabel.frame.height + 8 + arrowHeight)

        rangeLabel.pin
            .top(4)
            .hCenter()

        drawBubble()

        slider.pin
            .below(of: rangeBubbleView)
            .marginTop(0)
            .left(20)
            .right(20)
            .height(20)

        minLabel.sizeToFit()
        maxLabel.sizeToFit()

        let tickHeight: CGFloat = 4
        let tickContainerHeight: CGFloat

        if midLabelText != nil {
            midLabel.sizeToFit()
            tickContainerHeight = tickHeight + 2 + max(minLabel.frame.height, midLabel.frame.height, maxLabel.frame.height)
        } else {
            tickContainerHeight = tickHeight + 2 + max(minLabel.frame.height, maxLabel.frame.height)
        }

        minTickContainer.pin
            .below(of: slider)
            .marginTop(4)
            .left(20)
            .width(1)
            .height(tickContainerHeight)

        minTickView.pin
            .top()
            .left()
            .width(1)
            .height(tickHeight)

        minLabel.pin
            .below(of: minTickView)
            .marginTop(2)
            .left(minTickView.frame.midX - minLabel.frame.width / 2)

        maxTickContainer.pin
            .below(of: slider)
            .marginTop(4)
            .right(20)
            .width(1)
            .height(tickContainerHeight)

        maxTickView.pin
            .top()
            .right()
            .width(1)
            .height(tickHeight)

        maxLabel.pin
            .below(of: maxTickView)
            .marginTop(2)
            .left(maxTickView.frame.midX - maxLabel.frame.width / 2)

        if midLabelText != nil {
            midTickContainer.pin
                .below(of: slider)
                .marginTop(4)
                .hCenter()
                .width(1)
                .height(tickContainerHeight)

            midTickView.pin
                .top()
                .hCenter()
                .width(1)
                .height(tickHeight)

            midLabel.pin
                .below(of: midTickView)
                .marginTop(2)
                .hCenter()
        }
    }

    private func drawBubble() {
        let width = rangeBubbleView.bounds.width
        let height = rangeBubbleView.bounds.height
        let arrowWidth: CGFloat = 8
        let arrowHeight: CGFloat = 4
        let cornerRadius: CGFloat = 4
        let boxHeight = height - arrowHeight

        let path = UIBezierPath()

        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        path.addArc(withCenter: CGPoint(x: width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: width, y: boxHeight - cornerRadius))
        path.addArc(withCenter: CGPoint(x: width - cornerRadius, y: boxHeight - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: width / 2 + arrowWidth / 2, y: boxHeight))
        path.addLine(to: CGPoint(x: width / 2, y: boxHeight + arrowHeight))
        path.addLine(to: CGPoint(x: width / 2 - arrowWidth / 2, y: boxHeight))
        path.addLine(to: CGPoint(x: cornerRadius, y: boxHeight))
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: boxHeight - cornerRadius), radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
        path.close()

        bubbleShapeLayer.path = path.cgPath
        bubbleShapeLayer.fillColor = ColorSystem.gray0.cgColor
        bubbleShapeLayer.strokeColor = ColorSystem.gray30.cgColor
        bubbleShapeLayer.lineWidth = 1
    }
}
