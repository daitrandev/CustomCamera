//
//  CapturedHistory.swift
//  CustomCamera
//
//  Created by Dai Tran on 12/24/17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit

class CapturedHistoryViewController: UIViewController {
    
    let cellId = "cellId"
    
    var imageData: [Data]?
    var imageLabel: [String]?
    
    lazy var historyTableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    lazy var bottomToolbar: UIToolbar = {
        let toolBar = UIToolbar()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteRows))
        let deleteAllButton = UIBarButtonItem(title: "Delete All", style: .plain, target: self, action: #selector(deleteAllRows))
        toolBar.items = [deleteAllButton,flexibleSpace,deleteButton]
        return toolBar
    }()
    
    var bottomToolbarConstraints: [NSLayoutConstraint]?
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        
        UIApplication.shared.statusBarStyle = .default
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTableView))
        navigationItem.title = "History"
        
        view.addSubview(bottomToolbar)
        bottomToolbarConstraints = bottomToolbar.constraint(top: nil, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, topConstant: 0, bottomConstant: 50, leftConstant: 0, rightConstant: 0)
        
        view.addSubview(historyTableView)
        historyTableView.register(historyTableViewCell.self, forCellReuseIdentifier: cellId)
        _ = historyTableView.constraint(top: view.layoutMarginsGuide.topAnchor, bottom: bottomToolbar.topAnchor, left: view.leftAnchor, right: view.rightAnchor, topConstant: 0, bottomConstant: 0, leftConstant: 0, rightConstant: 0)
        historyTableView.allowsSelection = false
        historyTableView.allowsMultipleSelectionDuringEditing = true
        
        imageData = (UserDefaults.standard.array(forKey: "historyImage") as! [Data])
        imageLabel = (UserDefaults.standard.array(forKey: "historyImageLabel") as! [String])
    }
    
    @objc func editTableView(_ sender: UIBarButtonItem) {
        historyTableView.setEditing(!historyTableView.isEditing, animated: true)
        
        sender.title = historyTableView.isEditing ? "Cancel" : "Edit"
        bottomToolbarConstraints?[0].constant = historyTableView.isEditing ? 0 : 50
        
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func deleteRows() {
        guard let indexPathsForSelectedRows = historyTableView.indexPathsForSelectedRows?.sorted() else { return }
        guard let imageData = imageData else { return }

        var newImageData: [Data] = [Data]()
        var j: Int = 0
        for i in 0..<imageData.count {
            if (i == indexPathsForSelectedRows[j].row) {
                if (j < indexPathsForSelectedRows.count - 1) {
                    j += 1
                }
            } else {
                newImageData.append(imageData[i])
            }
        }
        self.imageData = newImageData.count == 0 ? nil : newImageData
        UserDefaults.standard.set(self.imageData, forKey: "historyImage")
        
        historyTableView.beginUpdates()
        historyTableView.deleteRows(at: indexPathsForSelectedRows, with: .fade)
        historyTableView.endUpdates()
    }
    
    @objc func deleteAllRows() {
        self.imageData = nil
        UserDefaults.standard.set(nil, forKey: "historyImage")
        let range = NSMakeRange(0, self.historyTableView.numberOfSections)
        let sections = NSIndexSet(indexesIn: range)
        self.historyTableView.reloadSections(sections as IndexSet, with: .fade)
        //historyTableView.reloadData()
    }

}

extension CapturedHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = imageData?.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! historyTableViewCell
        cell.historyImageView.image = UIImage(data: imageData![indexPath.row])
        cell.imageLabel.text = imageLabel?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            imageData?.remove(at: indexPath.row)
            imageData = imageData?.count == 0 ? nil : imageData
            UserDefaults.standard.set(imageData, forKey: "historyImage")
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
}

class historyTableViewCell: UITableViewCell{

    let historyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .green
        return imageView
    }()

    let imageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = "abc"
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(historyImageView)
        _ = historyImageView.constraint(top: contentView.topAnchor, bottom: contentView.bottomAnchor, left: contentView.leftAnchor, right: nil, topConstant: 8, bottomConstant: -8, leftConstant: 8, rightConstant: 0)
        historyImageView.widthAnchor.constraint(equalTo: historyImageView.heightAnchor).isActive = true

        contentView.addSubview(imageLabel)
        _ = imageLabel.constraint(top: nil, bottom: nil, left: nil, right: contentView.rightAnchor, topConstant: 0, bottomConstant: 0, leftConstant: 0, rightConstant: -8)
        imageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

