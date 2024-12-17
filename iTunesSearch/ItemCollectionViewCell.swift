//
//  ItemCollectionViewCell.swift
//  iTunesSearch
//
//  Created by Gwen Thelin on 12/13/24.
//

import UIKit

class ItemCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var detailLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var itemImageView: UIImageView!
	
	static let placeholder: UIImage = .init(systemName: "photo")!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		contentView.layer.cornerRadius = 8
		contentView.layer.masksToBounds = true
		contentView.layer.borderWidth = 0.5
		contentView.layer.borderColor = UIColor.lightGray.cgColor
		
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOpacity = 0.2
		layer.shadowOffset = CGSize(width: 0, height: 2)
		layer.shadowRadius = 4
		layer.masksToBounds = false
		
		itemImageView.layer.cornerRadius = 8
		itemImageView.clipsToBounds = true
		itemImageView.contentMode = .scaleAspectFill
		
		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		detailLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
		titleLabel.textColor = .label
		detailLabel.textColor = .secondaryLabel
	}
	
	override var isHighlighted: Bool {
		didSet {
			UIView.animate(withDuration: 0.2, animations: {
				self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
			})
		}
	}
	
	func createLayout() -> UICollectionViewLayout {
		UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.45), heightDimension: .absolute(250))
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
			group.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
			
			let section = NSCollectionLayoutSection(group: group)
			section.interGroupSpacing = 16
			section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
			
			return section
		}
	}
	
	func setupCollectionView(collectionView: UICollectionView) {
		collectionView.collectionViewLayout = createLayout()
		collectionView.backgroundColor = UIColor.systemGroupedBackground
	}
}

extension ItemCollectionViewCell: ItemDisplaying {
	func configure(for item: StoreItem, storeItemController: StoreItemController) {
		titleLabel.text = item.name
		detailLabel.text = item.artist
		itemImageView.image = storeItemController.getImage(from: item.artworkURL, placeholder: Self.placeholder)
	}
}
