//
//  StoreItemCollectionViewSectionHeader.swift
//  iTunesSearch
//
//  Created by Gwen Thelin on 12/19/24.
//

import UIKit

class StoreItemCollectionViewSectionHeader: UICollectionReusableView {
	let titleLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 17, weight: .semibold)
		label.textColor = .label

		
		return label
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupView()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupView()
	}
	
	func setTitle(_ title: String) {
		titleLabel.text = title
	}
	
	private func setupView() {
		backgroundColor = .systemGray5
		
		addSubview(titleLabel)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
			titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
			titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
			titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
		])
	}
}
