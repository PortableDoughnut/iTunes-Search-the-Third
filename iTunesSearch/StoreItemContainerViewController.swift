import UIKit

@MainActor
class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
	@IBOutlet var tableContainerView: UIView!
	@IBOutlet var collectionContainerView: UIView!
	
	let searchController = UISearchController()
	let storeItemController = StoreItemController()
	
	var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem.ID>!
	var tableViewDataSource: UITableViewDiffableDataSource<String, StoreItem.ID>!
	
	var items = [StoreItem]()
	let queryOptions = ["movie", "music", "software", "ebook"]
	
	var searchTask: Task<Void, Never>?
	var tableViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
	var collectionViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
	
	var itemIdentifiersSnapshot: NSDiffableDataSourceSnapshot<String, StoreItem.ID> {
		var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem.ID>()
		snapshot.appendSections(["Results"])
		snapshot.appendItems(items.map { $0.id })
		return snapshot
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.searchController = searchController
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.automaticallyShowsSearchResultsController = true
		searchController.searchBar.showsScopeBar = true
		searchController.searchBar.scopeButtonTitles = ["Movies", "Music", "Apps", "Books"]
	}
	
	func configureTableViewDataSource(_ tableView: UITableView) {
		tableViewDataSource = UITableViewDiffableDataSource(
			tableView: tableView,
			cellProvider: { [weak self] tableView, indexPath, itemIdentifier in
				guard let self = self,
					  let item = self.items.first(where: { $0.id == itemIdentifier })
				else { return nil }
				
				guard let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as? ItemTableViewCell else {
					return nil
				}
				
				cell.configure(for: item, storeItemController: self.storeItemController)
				
				if cell.itemImageView.image == ItemTableViewCell.placeholder {
					self.tableViewImageLoadTasks[indexPath]?.cancel()
					self.tableViewImageLoadTasks[indexPath] = Task { [weak self] in
						guard let self else { return }
						defer { self.tableViewImageLoadTasks[indexPath] = nil }
						do {
							_ = try await self.storeItemController.fetchImage(from: item.artworkURL)
							var snapshot = self.tableViewDataSource.snapshot()
							snapshot.reconfigureItems([itemIdentifier])
							await self.tableViewDataSource.apply(snapshot, animatingDifferences: true)
						} catch {
							print("Error fetching image: \(error)")
						}
					}
				}
				return cell
			})
	}
	
	func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
		let nib: UINib = UINib(nibName: "ItemCollectionViewCell", bundle: .main)
		let cellRegistration = UICollectionView.CellRegistration<ItemCollectionViewCell, StoreItem.ID>(
			cellNib: nib
		) { [weak self] cell, indexPath, itemIdentifier in
			guard let self = self,
				  let item = self.items.first(where: { $0.id == itemIdentifier })
			else { return }
			
			cell.configure(for: item, storeItemController: self.storeItemController)
			
			if cell.itemImageView.image == ItemCollectionViewCell.placeholder {
				self.collectionViewImageLoadTasks[indexPath]?.cancel()
				self.collectionViewImageLoadTasks[indexPath] = Task { [weak self] in
					guard let self else { return }
					defer { self.collectionViewImageLoadTasks[indexPath] = nil }
					do {
						_ = try await self.storeItemController.fetchImage(from: item.artworkURL)
						var snapshot = self.collectionViewDataSource.snapshot()
						snapshot.reconfigureItems([itemIdentifier])
						await self.collectionViewDataSource.apply(snapshot, animatingDifferences: true)
					} catch {
						print("Error fetching image: \(error)")
					}
				}
			}
		}
		
		collectionViewDataSource = UICollectionViewDiffableDataSource<String, StoreItem.ID>(
			collectionView: collectionView,
			cellProvider: { collectionView, indexPath, identifier in
				collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
			})
	}
	
	@IBAction func switchContainerView(_ sender: UISegmentedControl) {
		tableContainerView.isHidden.toggle()
		collectionContainerView.isHidden.toggle()
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchMatchingItems), object: nil)
		perform(#selector(fetchMatchingItems), with: nil, afterDelay: 0.3)
	}
	
	@objc func fetchMatchingItems() {
		items = []
		let searchTerm = searchController.searchBar.text ?? ""
		let mediaType = queryOptions[searchController.searchBar.selectedScopeButtonIndex]
		
		searchTask?.cancel()
		searchTask = Task { [weak self] in
			guard let self else { return }
			if searchTerm.isEmpty {
				await tableViewDataSource.apply(NSDiffableDataSourceSnapshot(), animatingDifferences: true)
				await collectionViewDataSource.apply(NSDiffableDataSourceSnapshot(), animatingDifferences: true)
				return
			}
			
			do {
				let query = [
					"term": searchTerm,
					"media": mediaType,
					"lang": "en_us",
					"limit": "20"
				]
				let items = try await self.storeItemController.fetchItems(matching: query)
				if searchTerm == self.searchController.searchBar.text &&
					mediaType == self.queryOptions[self.searchController.searchBar.selectedScopeButtonIndex] {
					self.items = items
				}
			} catch {
				print("Error fetching items: \(error)")
			}
			
			await tableViewDataSource.apply(self.itemIdentifiersSnapshot, animatingDifferences: true)
			await collectionViewDataSource.apply(self.itemIdentifiersSnapshot, animatingDifferences: true)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let tableViewController = segue.destination as? StoreItemListTableViewController {
			configureTableViewDataSource(tableViewController.tableView)
		} else if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
			configureCollectionViewDataSource(collectionViewController.collectionView)
		}
	}
}
