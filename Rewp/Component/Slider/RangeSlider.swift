//
//  RangeSlider.swift
//  Rewp
//
//  Created by 금가경 on 01/10/26.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout

final class RangeSlider: UIView {
    struct Output {
        let rangeChanged: Observable<(min: Int, max: Int)>
    }
    
    private var minValue: Int = 0
    private var maxValue: Int = 100
    private var currentMinValue: Int = 0
    private var currentMaxValue: Int = 100
    private let step: Int = 1
    
    private let rangeChangedRelay = PublishRelay<(min: Int, max: Int)>()
    
    private let trackView = UIView()
    private let inactiveLeftTrackView = UIView()
    private let activeTrackView = UIView()
    private let inactiveRightTrackView = UIView()
    private let minThumbView = UIView()
    private let maxThumbView = UIView()
    
    private var minThumbCenterX: CGFloat = 0
    private var maxThumbCenterX: CGFloat = 0
    private var trackWidth: CGFloat = 0

    private var activeThumb: UIView?

    private let thumbSize: CGFloat = 20
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(min: Int, max: Int, currentMin: Int, currentMax: Int) {
        self.minValue = min
        self.maxValue = max
        self.currentMinValue = currentMin
        self.currentMaxValue = currentMax
        updateThumbPositions(animated: false)
    }
    
    func transform() -> Output {
        return Output(
            rangeChanged: rangeChangedRelay.asObservable()
        )
    }
    
    private func setupUI() {
        addSubview(trackView)
        addSubview(inactiveLeftTrackView)
        addSubview(activeTrackView)
        addSubview(inactiveRightTrackView)
        addSubview(minThumbView)
        addSubview(maxThumbView)
        
        trackView.backgroundColor = .clear
        
        inactiveLeftTrackView.backgroundColor = ColorSystem.gray30
        inactiveLeftTrackView.layer.cornerRadius = 1
        
        activeTrackView.layer.cornerRadius = 1
        activeTrackView.clipsToBounds = true
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ColorSystem.brightWood.cgColor, ColorSystem.deepWood.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        activeTrackView.layer.insertSublayer(gradientLayer, at: 0)
        
        inactiveRightTrackView.backgroundColor = ColorSystem.gray30
        inactiveRightTrackView.layer.cornerRadius = 1

        configureThumb(minThumbView, borderColor: ColorSystem.brightWood)
        configureThumb(maxThumbView, borderColor: ColorSystem.deepWood)
        
        let minPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMinPan(_:)))
        minThumbView.addGestureRecognizer(minPanGesture)
        
        let maxPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMaxPan(_:)))
        maxThumbView.addGestureRecognizer(maxPanGesture)
    }
    
    private func configureThumb(_ thumb: UIView, borderColor: UIColor) {
        thumb.backgroundColor = ColorSystem.gray0
        thumb.layer.cornerRadius = thumbSize / 2
        thumb.layer.borderWidth = 3
        thumb.layer.borderColor = borderColor.cgColor
        thumb.layer.applyShadow(ShadowSystem.mdEmphasis)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        trackView.pin
            .left()
            .right()
            .vCenter()
            .height(2)
        
        trackWidth = trackView.frame.width
        
        updateThumbPositions(animated: false)
        
        layoutTracks()
    }
    
    private func layoutTracks() {
        inactiveLeftTrackView.pin
            .left()
            .vCenter()
            .width(minThumbCenterX)
            .height(6)
        
        activeTrackView.pin
            .left(minThumbCenterX)
            .vCenter()
            .width(maxThumbCenterX - minThumbCenterX)
            .height(6)
        
        if let gradientLayer = activeTrackView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = activeTrackView.bounds
        }
        
        inactiveRightTrackView.pin
            .left(maxThumbCenterX)
            .vCenter()
            .width(trackWidth - maxThumbCenterX)
            .height(6)
        
        minThumbView.pin
            .size(thumbSize)
            .vCenter()
            .left(minThumbCenterX - thumbSize / 2)

        maxThumbView.pin
            .size(thumbSize)
            .vCenter()
            .left(maxThumbCenterX - thumbSize / 2)
    }
    
    @objc private func handleMinPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: trackView)

        let ratio = max(0, min(1, location.x / trackWidth))
        let rawValue = CGFloat(minValue) + ratio * CGFloat(maxValue - minValue)
        let steppedValue = Int(round(rawValue / CGFloat(step))) * step
        let newMinValue = max(minValue, min(currentMaxValue, steppedValue))

        guard newMinValue != currentMinValue else { return }

        currentMinValue = newMinValue
        let finalRatio = CGFloat(currentMinValue - minValue) / CGFloat(maxValue - minValue)
        minThumbCenterX = trackWidth * finalRatio

        layoutTracks()
        rangeChangedRelay.accept((min: currentMinValue, max: currentMaxValue))
    }

    @objc private func handleMaxPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: trackView)

        let ratio = max(0, min(1, location.x / trackWidth))
        let rawValue = CGFloat(minValue) + ratio * CGFloat(maxValue - minValue)
        let steppedValue = Int(round(rawValue / CGFloat(step))) * step
        let newMaxValue = max(currentMinValue, min(maxValue, steppedValue))

        guard newMaxValue != currentMaxValue else { return }

        currentMaxValue = newMaxValue
        let finalRatio = CGFloat(currentMaxValue - minValue) / CGFloat(maxValue - minValue)
        maxThumbCenterX = trackWidth * finalRatio

        layoutTracks()
        rangeChangedRelay.accept((min: currentMinValue, max: currentMaxValue))
    }
    
    private func updateThumbPositions(animated: Bool) {
        let minRatio = CGFloat(currentMinValue - minValue) / CGFloat(maxValue - minValue)
        let maxRatio = CGFloat(currentMaxValue - minValue) / CGFloat(maxValue - minValue)
        
        minThumbCenterX = trackWidth * minRatio
        maxThumbCenterX = trackWidth * maxRatio
        
        self.layoutTracks()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let minThumbFrame = minThumbView.frame.insetBy(dx: -10, dy: -10)
        let maxThumbFrame = maxThumbView.frame.insetBy(dx: -10, dy: -10)
        return minThumbFrame.contains(point) || maxThumbFrame.contains(point) || super.point(inside: point, with: event)
    }
}
