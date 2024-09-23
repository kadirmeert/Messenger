//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Kadir Yildiz on 11/9/2024.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: (([String: String]) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    private var hasFetched = false
    private var results = [[String: String]]()


    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for contacts"
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results Found"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .lightGray
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        view.addSubview(searchBar)
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 100)
    }
    
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

}
extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)

        })
        
    }
    
    
}
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        searchUsers(query: text)
    }
    func searchUsers(query: String) {
        
        if hasFetched {
            filterUsers(with: query)
        }
        else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                   
                case .failure(let error):
                    print("Failed to get users: \(error)")
                    
                }
            })
        }
    }
    func filterUsers(with term: String) {
        guard hasFetched else {
            return
        }
        self.spinner.dismiss()
        
        let results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultLabel.isHidden = false
            tableView.isHidden = true
        }
        else {
            noResultLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
