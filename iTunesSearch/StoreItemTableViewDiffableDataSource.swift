//
//  StoreItemTableViewDiffableDataSource.swift
//  iTunesSearch
//
//  Created by Gwen Thelin on 12/19/24.
//

import UIKit

@MainActor
class StoreItemTableViewDiffableDataSource: UITableViewDiffableDataSource<String, StoreItem.ID> {
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		snapshot().sectionIdentifiers[section]
	}
}
