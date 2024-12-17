//
//  ItemDisplaying.swift
//  iTunesSearch
//
//  Created by Gwen Thelin on 12/16/24.
//

import UIKit

protocol ItemDisplaying {
	static var placeholder: UIImage { get }
	
	var itemImageView: UIImageView! { get set }
	var titleLabel: UILabel! { get set }
	var detailLabel: UILabel! { get set }
}

@MainActor
extension ItemDisplaying {
	func configure(for item: StoreItem, storeItemController: StoreItemController) {
		titleLabel.text = item.name
		detailLabel.text = item.artist
		itemImageView.image = storeItemController.getImage(from: item.artworkURL, placeholder: Self.placeholder)
	}
}
