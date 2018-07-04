//
//  StartViewController.swift
//  spark-demo
//
//  Created by alexeym on 01/03/2018.
//  Copyright © 2018 holaspark. All rights reserved.
//

import UIKit
import SparkLib

class StartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var customerLabel: UITextField!
    @IBOutlet weak var customerHistoryTable: UITableView!
    
    let defaultCustomerID: String = "sparkdemo"
    var customerID: String!
    var customerHistory: [String]!
    var customerHistoryEnabled: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.register(defaults: [
            "videos_per_customer": 10,
            "customer_history": [],
            "customer_history_enabled": true,
        ])
        UserDefaults.standard.synchronize()
        self.customerLabel.text = defaultCustomerID
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(willEnterForeground(_:)),
            name: .UIApplicationWillEnterForeground, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.updateRecentLoginTable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @objc func willEnterForeground(_ notification:NSNotification!) {
        self.updateRecentLoginTable()
    }
    
    func updateRecentLoginTable() -> Void {
        self.customerHistory = UserDefaults.standard.array(
            forKey: "customer_history") as! [String]? ?? []
        self.customerHistoryEnabled = UserDefaults.standard.bool(
            forKey: "customer_history_enabled")
        if !self.customerHistoryEnabled || self.customerHistory.count<=0 {
            self.customerHistoryTable.isHidden = true
            return
        }
        if self.customerHistoryTable.tableHeaderView == nil
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0,
                width: customerHistoryTable.frame.width, height: 40))
            label.text = "Recent logins:"
            label.textColor = UIColor.gray
            self.customerHistoryTable.register(UITableViewCell.self,
                forCellReuseIdentifier: "cell")
            self.customerHistoryTable.delegate = self
            self.customerHistoryTable.dataSource = self
            self.customerHistoryTable.tableHeaderView = label
        }
        self.customerHistoryTable.isHidden = false
    }
    
    func updateCustomerHistory(customer: String) -> Void {
        if let idx = self.customerHistory.index(of: customer) {
            self.customerHistory.remove(at: idx)
        }
        self.customerHistory.insert(customer, at: 0)
        self.saveCustomerHistory(max: 10)
    }
    
    func saveCustomerHistory(max: Int) -> Void {
        if (self.customerHistory.count>max) {
            self.customerHistory.removeSubrange(
                max..<self.customerHistory.count)
        }
        UserDefaults.standard.set(self.customerHistory,
            forKey: "customer_history")
        UserDefaults.standard.synchronize()
        self.customerHistoryTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.customerHistory.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.customerHistoryTable.dequeueReusableCell(withIdentifier: "cell") {
            cell.textLabel?.text = self.customerHistory[indexPath.row]
            cell.textLabel?.textColor = UIColor.gray
            cell.selectionStyle = .none
            return cell
        }
        // should not happends
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.customerLabel.text = self.customerHistory[indexPath.row]
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "start") {
            if let vc = segue.destination as? VideoListViewController {
                let customerID: String

                if let newID = customerLabel.text, !newID.isEmpty {
                    customerID = newID
                } else {
                    customerID = defaultCustomerID
                }
                SparkAPI.finalize()
                let api = SparkAPI.getAPI(customerID)
                if (self.customerID==nil) { // first init
                    api.setLogLevel(.info)
                    api.register(forNotifications: [.alert, .sound],
                         usingRemoteNotifications: true,
                         withCompletionBlock: { (error) in
                            print("notification registration result:",
                                error ?? "success");
                    })
                }
                
                self.customerID = customerID
                vc.customerID = customerID
                updateCustomerHistory(customer: customerID)
            }
        }
    }

}
