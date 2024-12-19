import UIKit

@MainActor
class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
	@IBOutlet var tableContainerView: UIView!
	@IBOutlet var collectionContainerView: UIView!
	
	let searchController = UISearchController()
	let storeItemController = StoreItemController()
	
	var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem.ID>!
	var tableViewDataSource: StoreItemTableViewDiffableDataSource!
	
	var items = [StoreItem]()
	var selectedSearchScope: SearchScope {
		let selectedIndex = searchController.searchBar.selectedScopeButtonIndex
		let searchScope = SearchScope.allCases[selectedIndex]
		
		return searchScope
	}
	
	var searchTask: Task<Void, Never>?
	var tableViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
	var collectionViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
	
	var itemIdentifiersSnapshot: NSDiffableDataSourceSnapshot<String, StoreItem.ID> = .init()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.searchController = searchController
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.automaticallyShowsSearchResultsController = true
		searchController.searchBar.showsScopeBar = true
		searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map(\.title)
	}
	
	func createSectionedSnapshot(from items: [StoreItem]) -> NSDiffableDataSourceSnapshot<String, StoreItem.ID> {
		let movies: [StoreItem] = items.filter { $0.kind == "feature_movie" }
		let music: [StoreItem] = items.filter {
			$0.kind == "song" || $0.kind == "album"
		}
		let apps: [StoreItem] = items.filter { $0.kind == "software" }
		let books: [StoreItem] = items.filter { $0.kind == "ebook" }
		
		let grouped: [(SearchScope, [StoreItem])] = [
			(.movies, movies),
			(.music, music),
			(.apps, apps),
			(.books, books)
		]
		
		var snapshot: NSDiffableDataSourceSnapshot<String, StoreItem.ID> = .init()
		grouped.forEach {
			(scope, items) in
			
			if items.count > 0 {
				snapshot.appendSections([scope.title])
				snapshot.appendItems(items.map(\.id), toSection: scope.title)
			}
		}
		
		return snapshot
	}
	
	func configureTableViewDataSource(_ tableView: UITableView) {
		tableViewDataSource = .init(
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
			
			let headerRegistration = UICollectionView.SupplementaryRegistration<StoreItemCollectionViewSectionHeader>(elementKind: "Header") {
				[weak self] headerView, elementKind, indexPath in
				
				guard let self else { return }
				
				let title = itemIdentifiersSnapshot.sectionIdentifiers[indexPath.section]
				headerView.setTitle(title)
			}
				
			collectionViewDataSource.supplementaryViewProvider = {
				collectionView, kind, indexPath -> UICollectionReusableView? in
				
				collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
			}
			
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
	
	func fetchAndHandleItemsForSearchScopes(
		_ searchScopes: [SearchScope],
		withSearchTerm searchTerm: String
	) async throws {
		try await withThrowingTaskGroup(
			of: (SearchScope, [StoreItem]).self
		) {
			group in
			for searchScope in searchScopes {
				group.addTask {
					try Task.checkCancellation()
					
					let query = [
						"term": searchTerm,
						"media": searchScope.mediaType,
						"lang": "en_us",
						"limit": "50"
					]
					
					return (searchScope, try await self.storeItemController.fetchItems(matching: query))
				}
			}
			for try await(searchScope, items) in group {
				try Task.checkCancellation()
				if searchTerm == self.searchController.searchBar.text &&
					(self.selectedSearchScope == .all || searchScope == self.selectedSearchScope) {
					await handleFetchedItems(items)
				}
			}
		}
	}
	
	func handleFetchedItems(_ items: [StoreItem]) async {
		self.items += items
		
		itemIdentifiersSnapshot = createSectionedSnapshot(from: self.items)
		
		await tableViewDataSource.apply(itemIdentifiersSnapshot, animatingDifferences: true)
		await collectionViewDataSource.apply(itemIdentifiersSnapshot, animatingDifferences: true)
	}
	
	@objc func fetchMatchingItems() {
		itemIdentifiersSnapshot.deleteAllItems()
		items = []
		
		let searchTerm = searchController.searchBar.text ?? ""
		let searchScopes: [SearchScope]
		
		if selectedSearchScope == .all {
			searchScopes = [.movies, .music, .apps, .books]
		} else {
			searchScopes = [selectedSearchScope]
		}
		
		searchTask?.cancel() // Cancel previous task
		searchTask = Task { [weak self] in
			guard let self else { return }
			
			if searchTerm.isEmpty {
				Task { @MainActor in
					await self.tableViewDataSource.apply(NSDiffableDataSourceSnapshot(), animatingDifferences: true)
					await self.collectionViewDataSource.apply(NSDiffableDataSourceSnapshot(), animatingDifferences: true)
				}
				return
			}
			
			do {
				try await self.fetchAndHandleItemsForSearchScopes(searchScopes, withSearchTerm: searchTerm)
			} catch is CancellationError {
					// Handle cancellation gracefully
			} catch {
				print("Error fetching items: \(error)")
			}
			
			searchTask = nil
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
