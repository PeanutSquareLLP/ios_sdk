//
//  SparkPlayerMenuViewController.swift
//  SparkPlayer
//
//  Created by alexeym on 02/03/2018.
//

import UIKit

class SparkPlayerMenuViewController: UIViewController {
    var UINibName: String {
        get { return "SparkPlayerMenu" }
    }

    override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            return .custom
        }

        set {}
    }

    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            return SparkPlayerMenuTransitionDelegate()
        }

        set {}
    }

    var menuView: SparkPlayerMenu {
        get {
            return self.view as! SparkPlayerMenu
        }
    }

    @IBOutlet weak var collectionView: UICollectionView?
    var menuFooterHeight: CGFloat = 500

    var cancelItem: MenuItem?
    var closeItem: MenuItem?
    var items: [MenuItem] = [] {
        didSet {
            reloadMenu()
        }
    }
    var activeItems: [MenuItem] = []

    public override func loadView() {
        guard let resourceBundle = SparkPlayer.getResourceBundle() else {
            return super.loadView()
        }
        view = resourceBundle.loadNibNamed(UINibName, owner: self, options: nil)?.first as! SparkPlayerMenu
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let cancelButton = menuView.cancelButton {
            if let item = self.cancelItem ?? self.closeItem {
                menuView.setupCancelButton(item)
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(SparkPlayerMenuViewController.onCancelTap))
            cancelButton.isUserInteractionEnabled = true
            cancelButton.addGestureRecognizer(tap)
        }

        if let collectionView = collectionView {
            let tap = UITapGestureRecognizer(target: self, action: #selector(SparkPlayerMenuViewController.onCloseTap))
            tap.delegate = self
            collectionView.addGestureRecognizer(tap)
        }

    }

    override var shouldAutorotate: Bool {
        return false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menuFooterHeight = self.view.frame.height
        reloadMenu()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        menuFooterHeight = self.view.frame.height
        updateMenuContentInset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func performClose(_ menuItem: MenuItem?) {
        guard let action = menuItem?.action else {
            dismiss(animated: true, completion: nil)
            return
        }

        action()
    }

    @objc func onCancelTap() {
        performClose(cancelItem ?? closeItem)
    }

    @objc func onCloseTap() {
        performClose(closeItem)
    }

}

extension SparkPlayerMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = self.collectionView else {
            return true
        }

        let point = gestureRecognizer.location(in: view)
        let indexPath = view.indexPathForItem(at: point)
        return indexPath == nil
    }
}

extension SparkPlayerMenuViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func reloadMenu() {
        activeItems = items.filter( { (item: MenuItem) -> Bool in
            return !item.isDisabled()
        })
        if let collection = self.collectionView {
            collection.reloadData()
        }
    }

    func getMenuItem(_ indexPath: IndexPath) -> MenuItem? {
        let row = indexPath.row

        guard row < activeItems.count else {
            return nil
        }

        return activeItems[row]
    }
    func menuHeight() -> CGFloat {
        return collectionContentHeight() + menuView.cancelButton.frame.height
    }

    func updateMenuContentInset() {
        if let collection = self.collectionView {
            let contentInsetTop = collection.bounds.size.height - collectionContentHeight()
            collection.contentInset = UIEdgeInsetsMake(max(0, contentInsetTop), 0, 0, 0)
        }
    }

    func collectionContentHeight() -> CGFloat {
        guard let collection = self.collectionView else {
            return 0
        }

        let numRows = collectionView(collection, numberOfItemsInSection: 0)
        var contentHeight: CGFloat = 0

        for i in 0..<numRows {
            let rowSize = collectionView(collection, layout: collection.collectionViewLayout, sizeForItemAt: IndexPath(item: i, section: 0))
            contentHeight += rowSize.height
        }

        return max(0, contentHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activeItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "menuCell", for: indexPath) as? SparkPlayerMenuCell else {
            return UICollectionViewCell()
        }

        if let item = getMenuItem(indexPath) {
            cell.setup(item)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        getMenuItem(indexPath)?.action?()
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footerView", for: indexPath)

        guard kind == UICollectionElementKindSectionFooter else {
            print("Should not happens")
            return view
        }

        view.backgroundColor = UIColor.SparkPlayer.menuBackground
        view.frame.size.height = menuFooterHeight

        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.contentSize.width, height: 1)
    }

}
