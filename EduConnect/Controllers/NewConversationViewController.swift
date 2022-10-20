//
//  NewConversationViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 4/30/22.
//

import UIKit

//will use this code, but not the search bar
class NewConversationViewController: UIViewController {
    
    public var completion: (([String:String]) -> (Void))?
    
    private var users = [[String: String]]()
    private var hasFetched = false
    //results shown in the table
    private var results = [[String: String]]()

    //create a seach bar
    private let searchBar: UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .white
        searchBar.delegate = self
        //put the bar into the navigation bar
        navigationController?.navigationBar.topItem?.titleView = searchBar
        //cancel
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action:#selector(dismissSelf))
        //show the typing
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y:(view.height - 200)/2,
                                      width:view.width/2,
                                      height:200)
    }
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }

}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    //selecting a row
    //selected a person - will adapt this to my table view
    //the table will have 2 buttons, chat and view profile
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        //start conversation
        
        //gets the user object at that row
        let targetUserData = results[indexPath.row]
        
        //pass through the user data, and on completion dismiss
        dismiss(animated: true, completion:{ [weak self] in
            self?.completion?(targetUserData)
        })
        
    }
}

extension NewConversationViewController: UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with:"").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        self.searchUsers(query:text)
    }
    
    //search the users and update table view
    func searchUsers(query: String){
        //check if the array has firebase results
        //if it does: filter
        //if not, fetch then filter
        //update the UI, either show the results or show the no results label
        if hasFetched {
            //filter
            filterUsers(with: query)
        }
        else {
            DatabaseManager.shared.getAllUsers(completion: {[weak self] result in
                switch result{
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            })
        }
    }
    
    //filter out users based on search
    func filterUsers(with term: String){
        //update the UI, either show the results or show no results label
        guard hasFetched else{
            return
        }
        let results: [[String:String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            //assign it to results if it is working
            return name.hasPrefix(term.lowercased())
        })
        self.results = results
        updateUI()
    }
    
    func updateUI(){
        if results.isEmpty{
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            print("show the table")
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData() //IMPORTANT
        }
    }
}
