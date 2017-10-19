//
//  CollectionViewController.swift
//  SEDaily-IOS
//
//  Created by Craig Holliday on 10/12/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import UIKit
import KoalaTeaFlowLayout

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController {
    lazy var skeletonCollectionView: SkeletonCollectionView = {
        return SkeletonCollectionView(frame: self.collectionView!.frame)
    }()
    
    var type: String
    var tabTitle = ""
    var tags: [Int]
    var categories: [Int]
    
    // ViewModelController
    private let podcastViewModelController = PodcastViewModelController()
    
    init(collectionViewLayout layout: UICollectionViewLayout, tags: [Int] = [], categories: [Int] = [], type: String) {
        self.type = type
        self.tags = tags
        self.categories = categories
        
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(PodcastCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        let layout = KoalaTeaFlowLayout(cellWidth: 158,
                                        cellHeight: 250,
                                        topBottomMargin: 12,
                                        leftRightMargin: 20,
                                        cellSpacing: 8)
        self.collectionView?.collectionViewLayout = layout
        self.collectionView?.backgroundColor = .white
        
        // Load initial data
        self.getData(lastIdentifier: "", nextPage: 0)
        
        // User Login observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.loginObserver), name: .loginChanged, object: nil)
        
        
        self.collectionView?.addSubview(skeletonCollectionView)
    }
    
    @objc func loginObserver() {
        self.getData(lastIdentifier: "", nextPage: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if podcastViewModelController.viewModelsCount > 0 {
            self.skeletonCollectionView.fadeOut(duration: 0.5, completion: nil)
        }
        return podcastViewModelController.viewModelsCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PodcastCell
    
        // Configure the cell
        if let viewModel = podcastViewModelController.viewModel(at: indexPath.row) {
            cell.viewModel = viewModel
            if let lastIndexPath = self.collectionView?.indexPathForLastItem {
                if let lastItem = podcastViewModelController.viewModel(at: lastIndexPath.row) {
                    self.checkPage(currentIndexPath: indexPath,
                                   lastIndexPath: lastIndexPath,
                                   lastIdentifier: lastItem.uploadDateiso8601)
                }
            }
        }
    
        return cell
    }
    var loading = false
    let pageSize = 10
    let preloadMargin = 5
    
    var lastLoadedPage = 0
    
    func checkPage(currentIndexPath: IndexPath, lastIndexPath: IndexPath, lastIdentifier: String) {
        let nextPage: Int = Int(currentIndexPath.item / self.pageSize) + 1
        let preloadIndex = nextPage * self.pageSize - self.preloadMargin
        
        if (currentIndexPath.item >= preloadIndex && self.lastLoadedPage < nextPage) || currentIndexPath == lastIndexPath {
            // @TODO: Turn lastIdentifier into some T
            self.getData(lastIdentifier: lastIdentifier, nextPage: nextPage)
        }
    }
    
    func getData(lastIdentifier: String, nextPage: Int) {
        guard self.loading == false else { return }
        self.loading = true
        podcastViewModelController.fetchData(createdAtBefore: lastIdentifier, tags: self.tags, categories: self.categories, page: nextPage, onSucces: {
            self.loading = false
            self.lastLoadedPage = nextPage
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }) { (apiError) in
            self.loading = false
            print(apiError)
        }
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let viewModel = podcastViewModelController.viewModel(at: indexPath.row) {
            let vc = PostDetailViewController()
            vc.model = viewModel
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}
