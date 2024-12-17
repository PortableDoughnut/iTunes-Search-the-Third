
import UIKit

class StoreItemCollectionViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		let itemSize: NSCollectionLayoutSize = .init(
			widthDimension: .fractionalWidth(0.3),
			heightDimension: .fractionalHeight(1)
		)
		let item: NSCollectionLayoutItem = .init(layoutSize: itemSize)
		
		let groupSize: NSCollectionLayoutSize = .init(
			widthDimension: .fractionalWidth(1),
			heightDimension: .fractionalHeight(0.5)
		)
		let group: NSCollectionLayoutGroup = .horizontal(
			layoutSize: groupSize,
			subitem: item,
			count: 3
		)
		
		let section: NSCollectionLayoutSection = .init(group: group)
		section.contentInsets = NSDirectionalEdgeInsets(
			top: 8,
			leading: 8,
			bottom: 8,
			trailing: 8
		)
		section.interGroupSpacing = 8
		
		collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: section)
    }
    
	
}
