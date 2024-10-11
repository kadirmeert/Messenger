//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Kadir Yildiz on 11/9/2024.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    private var hasFetched = false
    private var results = [SearchResult]()


    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for contacts"
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
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
        
        view.backgroundColor = .systemBackground
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
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)

        })
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        self.spinner.dismiss()
        
        let results: [SearchResult] = self.users.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"],
                  let name = $0["name"] else {
                return nil
            }
            return SearchResult(name: name, email: email)
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

struct SearchResult {
    let name: String
    let email: String
}
