//
//  TrackListViewController.swift
//  Treble
//
//  Created by Andy Liang on 2016-02-05.
//  Copyright © 2016 Andy Liang. All Rights Reserved. MIT License.
//
//  Modified by Chris Eugene Mills for the Vancouver Art Gallery, April 2018
//

import UIKit
import MediaPlayer

private let reuseIdentifier = "reuseIdentifier"
class TrackListViewController: UITableViewController {
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private(set) var trackList: [MPMediaItem] = []
    
    var currentTrack: MPMediaItem! {
        didSet {
            defer {
                self.tableView.reloadData()
            }
            self.title = currentTrack?.albumTitle
            self.trackList = []
            guard let album = currentTrack?.albumTitle else { return }
            let predicate = MPMediaPropertyPredicate(value: album, forProperty: MPMediaItemPropertyAlbumTitle)
            self.trackList = MPMediaQuery(filterPredicates: [predicate]).items!
        }
    }
    
    override func loadView() {
        super.loadView()
        tableView.rowHeight = 48
        tableView.backgroundColor = .clear
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
        tableView.separatorInset.left = 42
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TrackItemCell.self, forCellReuseIdentifier: reuseIdentifier)
//        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(TrackListViewController.dismissView))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        self.updatePreferredContentSize()
    }
    
//    func updatePreferredContentSize() { // Adapt size to content, deprecated
//        let height = min(self.tableView.contentSize.height, UIScreen.main.bounds.height*0.8)
//        guard height != preferredContentSize.height else { return }
//        let contentSize = CGSize(width: UIDevice.current.userInterfaceIdiom == .pad ? 320 : self.tableView.frame.width, height: height)
//        self.preferredContentSize = contentSize
//        self.navigationController?.preferredContentSize = contentSize
//    }

    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    var indexOfNowPlayingItem: Int {
        guard let title = musicPlayer.nowPlayingItem?.title else { return -1 }
        return self.trackList.map { $0.title! }.index(of: title) ?? -1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        defer { self.dismiss(animated: true, completion: self.musicPlayer.play) }
        guard indexPath.row != self.indexOfNowPlayingItem else { return }
        let selectedTrack = trackList[indexPath.row]
        musicPlayer.setQueue(with: MPMediaItemCollection(items: trackList))
        self.musicPlayer.nowPlayingItem = selectedTrack
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TrackItemCell
        
        cell.textLabel!.text = trackList[indexPath.row].title!
        
        let trackDuration = trackList[indexPath.row].playbackDuration
        cell.detailTextLabel!.text = trackDuration.stringRepresentation
        
        cell.indexString = indexPath.row == indexOfNowPlayingItem ? "▶︎" : "\(indexPath.row+1)"
        return cell
    }
    
}

extension TrackListViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return TrackListPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}

private extension TimeInterval {
    
    var stringRepresentation: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if (Int(self) >= 86400) {
            formatter.allowedUnits = [.day, .hour, .minute, .second]
        } else if (Int(self) >= 3600) {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else {
            formatter.allowedUnits = [.minute, .second]
        }
        
        return formatter.string(from: self)!
    }
    
}
