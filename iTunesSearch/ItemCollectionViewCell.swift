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
		contentView.layer.borderColor = UIColor.lightGray.cgColor
		
		layer.masksToBounds = false
		
		itemImageView.layer.cornerRadius = 8
		itemImageView.clipsToBounds = true
		itemImageView.contentMode = .scaleAspectFit
		
		itemImageView.translatesAutoresizingMaskIntoConstraints = false
		
		titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		detailLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
		titleLabel.textColor = .label
		detailLabel.textColor = .secondaryLabel
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		itemImageView.contentMode = .scaleAspectFit
		itemImageView.clipsToBounds = true
		contentView.addSubview(itemImageView)
		
		titleLabel.textColor = .white
		titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		titleLabel.textAlignment = .center
		titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
		contentView.addSubview(titleLabel)
		
		itemImageView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			itemImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			itemImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -4),
			
			titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
			titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
			titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
			titleLabel.heightAnchor.constraint(equalToConstant: 20)
		])
		
		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		
		setNeedsLayout()
		layoutIfNeeded()
		
		
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
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
			
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
			group.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
			
			let section = NSCollectionLayoutSection(group: group)
			section.interGroupSpacing = 4
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
