//
//  SubtitleSelectionBottomSheet.swift
//  Rewp
//
//  Created by 금가경 on 01/07/26.
//

import UIKit
import PinLayout
import Then
import RxSwift

final class SubtitleCell: UITableViewCell, IsIdentifiable {
    private let titleLabel = UILabel()
    private let checkmarkIcon = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark")
        $0.tintColor = ColorSystem.brightCoast
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.typography(FontSystem.Pretendard.body1, text: title)
        titleLabel.textColor = ColorSystem.gray90
        checkmarkIcon.isHidden = !isSelected
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        checkmarkIcon.pin
            .right(20)
            .vCenter()
            .size(20)

        titleLabel.pin
            .left(20)
            .right(to: checkmarkIcon.edge.left)
            .marginRight(12)
            .vCenter()
            .sizeToFit(.width)
    }
}

final class SubtitleSelectionBottomSheet: UIView {
    private let dimView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.alpha = 0
    }

    private let containerView = UIView().then {
        $0.backgroundColor = ColorSystem.gray0
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private let handleBar = UIView().then {
        $0.backgroundColor = ColorSystem.gray45
        $0.layer.cornerRadius = 2
    }

    private let titleLabel = UILabel().then {
        $0.typography(FontSystem.Pretendard.body2, text: "자막 선택")
        $0.textColor = ColorSystem.gray90
    }

    private let tableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.register(SubtitleCell.self, forCellReuseIdentifier: SubtitleCell.identifier)
    }

    private var subtitles: [SubtitleInfo] = []
    private var selectedLanguage: String?
    var onSubtitleSelected: ((SubtitleInfo?) -> Void)?

    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(dimView)
        addSubview(containerView)
        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        dimView.addGestureRecognizer(tapGesture)
    }

    @objc private func dimViewTapped() {
        hide()
    }

    func configure(subtitles: [SubtitleInfo], selectedLanguage: String?) {
        self.subtitles = subtitles
        self.selectedLanguage = selectedLanguage
        tableView.reloadData()
    }

    func show(in parentView: UIView) {
        frame = parentView.bounds
        parentView.addSubview(self)

        layoutSubviews()

        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.dimView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.bounds.height)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        dimView.pin.all()

        let tableHeight = min(CGFloat(subtitles.count + 1) * 56 + 100, bounds.height * 0.6)

        containerView.pin
            .bottom()
            .horizontally()
            .height(tableHeight)

        handleBar.pin
            .top(12)
            .hCenter()
            .width(40)
            .height(4)

        titleLabel.pin
            .below(of: handleBar)
            .marginTop(16)
            .left(20)
            .right(20)
            .sizeToFit(.width)

        tableView.pin
            .below(of: titleLabel)
            .marginTop(16)
            .horizontally()
            .bottom()
    }
}

extension SubtitleSelectionBottomSheet: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subtitles.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.identifier, for: indexPath) as! SubtitleCell

        if indexPath.row == 0 {
            cell.configure(title: "자막 끄기", isSelected: selectedLanguage == nil)
        } else {
            let subtitle = subtitles[indexPath.row - 1]
            cell.configure(
                title: subtitle.displayName,
                isSelected: subtitle.language == selectedLanguage
            )
        }

        return cell
    }
}

extension SubtitleSelectionBottomSheet: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            onSubtitleSelected?(nil)
        } else {
            let subtitle = subtitles[indexPath.row - 1]
            onSubtitleSelected?(subtitle)
        }
        hide()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
