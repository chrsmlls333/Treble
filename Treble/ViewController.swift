//
//  ViewController.swift
//  Treble
//
//  Created by Andy Liang on 2016-02-04.
//  Copyright © 2016 Andy Liang. All Rights Reserved. MIT License.
//
//  Modified by Chris Eugene Mills for the Vancouver Art Gallery, April 2018
//

import UIKit
import MediaPlayer
import AVFoundation

enum MusicType {
    case file
    case library
}

enum MetadataKey {
    case title
    case albumTitle
    case artist
    case type
    case creator
}

class ViewController: UIViewController {
    
    private let containerView = UIView()
    private let imageOuterView = UIView()
    private let imageInnerView = UIImageView()
    private let songTitleLabel: MarqueeLabel = MarqueeLabel(frame: .zero, duration: 8.0, fadeLength: 8)
    private let albumTitleLabel: MarqueeLabel = MarqueeLabel(frame: .zero, duration: 8.0, fadeLength: 8)
    
    private let backgroundImageView = UIImageView()
    private var backgroundView: UIVisualEffectView!
    private var vibrancyEffectView: UIVisualEffectView!
    
    private let playPauseButton = UIButton(type: .custom)
    private let nextTrackButton = UIButton(type: .custom)
    private let prevTrackButton = UIButton(type: .custom)
    private let musPickerButton = UIButton(type: .custom)
    private let icloudDocButton = UIButton(type: .custom)
    private let trackListButton = UIButton(type: .custom)
    
    fileprivate let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    fileprivate var audioPlayer: AVPlayer!
    fileprivate var audioFileName: String?
    fileprivate var audioArtistName: String?
    
    fileprivate var musicType: MusicType = .library {
        didSet {
            do {
                switch musicType {
                case .file:
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    UIApplication.shared.beginReceivingRemoteControlEvents()
                    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.restartPlayback), name: .AVPlayerItemDidPlayToEndTime, object: nil)
                case .library:
                    self.audioPlayer?.pause()
                    try AVAudioSession.sharedInstance().setActive(false, with: .notifyOthersOnDeactivation)
                    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
                    UIApplication.shared.endReceivingRemoteControlEvents()
                }
            } catch {
                print(error)
            }
            
        }
    }
    private let volumeSlider: MPVolumeView = MPVolumeView()
    
    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []
    private var containerConstraints: (top: NSLayoutConstraint, bottom: NSLayoutConstraint)!
    private var albumImageConstraints: (left: NSLayoutConstraint, right: NSLayoutConstraint, top: NSLayoutConstraint, bottom: NSLayoutConstraint)!
    
    private lazy var trackListView: TrackListViewController = TrackListViewController()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func loadView() {
        super.loadView()
        
        let blurEffect = UIBlurEffect(style: .dark)
        backgroundView = UIVisualEffectView(effect: blurEffect)
        vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.backgroundColor = .white
        
        volumeSlider.showsRouteButton = true
        volumeSlider.sizeToFit()
        
        imageOuterView.backgroundColor = .clear
        imageInnerView.isUserInteractionEnabled = true
        imageInnerView.contentMode = .scaleAspectFill
        imageInnerView.layer.cornerRadius = 12.0
        imageInnerView.layer.masksToBounds = true
        imageInnerView.backgroundColor = .white
        
        self.view.addSubview(backgroundImageView) // background image that is blurred
        self.view.addSubview(backgroundView) // blur view that blurs the image
        self.view.addSubview(containerView) // add one so I can use constraints
        containerView.addSubview(vibrancyEffectView) // the vibrancy view where everything else is added
        containerView.addSubview(volumeSlider) // add volume slider here so that it doesn't have the vibrancy effect
        containerView.addSubview(imageOuterView)
        imageOuterView.addSubview(imageInnerView)
        
        vibrancyEffectView.contentView.addSubview(musPickerButton)
        vibrancyEffectView.contentView.addSubview(songTitleLabel)
        vibrancyEffectView.contentView.addSubview(albumTitleLabel)
        vibrancyEffectView.contentView.addSubview(playPauseButton)
        vibrancyEffectView.contentView.addSubview(prevTrackButton)
        vibrancyEffectView.contentView.addSubview(nextTrackButton)
        vibrancyEffectView.contentView.addSubview(trackListButton)
        vibrancyEffectView.contentView.addSubview(icloudDocButton)
        
        let views: [UIView] = [containerView, backgroundImageView, backgroundView, vibrancyEffectView, imageOuterView, imageInnerView, musPickerButton, volumeSlider, songTitleLabel, albumTitleLabel, playPauseButton, prevTrackButton, nextTrackButton, trackListButton, icloudDocButton]
            
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        backgroundView.constrain(to: self.view)
        backgroundImageView.constrain(to: self.view)
        vibrancyEffectView.constrain(to: self.view)
		if #available(iOS 11.0, *) {
			containerView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).activate()
			containerView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).activate()
		} else {
			NSLayoutConstraint.activate(containerView.leading == self.view.leading, containerView.trailing == self.view.trailing)
		}
		
		
		
        self.containerConstraints = (containerView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).activate(),
									 containerView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).activate())
        
        self.verticalConstraints = [
            imageOuterView.top == containerView.top,
            imageOuterView.width == containerView.width * 0.85,
            imageOuterView.height == imageOuterView.width,
            imageOuterView.centerX == containerView.centerX,
			playPauseButton.centerX == songTitleLabel.centerX
        ]
        
        // separating the extra constraints because of swift limitations
        self.verticalConstraints.append(contentsOf: [
            songTitleLabel.leading == imageOuterView.leading,
            songTitleLabel.trailing == imageOuterView.trailing,
            songTitleLabel.top == imageOuterView.bottom + 28
        ])
        
        self.horizontalConstraints = [
            imageOuterView.height == containerView.height,
            imageOuterView.width == imageOuterView.height ~ UILayoutPriority(rawValue: 900),
            imageOuterView.leading == containerView.leading + 24,
            imageOuterView.centerY == containerView.centerY,
			playPauseButton.centerY == containerView.centerY
        ]
        
        // separating the extra constraints because of swift limitations
        self.horizontalConstraints.append(contentsOf: [
            songTitleLabel.leading == imageOuterView.trailing + 16,
            songTitleLabel.trailing == containerView.trailing - 16
        ])
        
        self.albumImageConstraints = ((imageInnerView.left  == imageOuterView.left).activate(),
                                      (imageInnerView.right == imageOuterView.right).activate(),
                                      (imageInnerView.top   == imageOuterView.top).activate(),
                                      (imageInnerView.bottom == imageOuterView.bottom).activate())
        
        let buttonSize: CGFloat = 48.0, margin: CGFloat = 24.0
        
        musPickerButton.constrainSize(to: 36)
        trackListButton.constrainSize(to: 36)
        icloudDocButton.constrainSize(to: 36)
        playPauseButton.constrainSize(to: buttonSize)
        prevTrackButton.constrainSize(to: buttonSize)
        nextTrackButton.constrainSize(to: buttonSize)
        
        NSLayoutConstraint.activate(imageInnerView.width <= imageOuterView.width,
                                    imageInnerView.height <= imageOuterView.height,
                                    musPickerButton.bottom == volumeSlider.top - 16,
                                    musPickerButton.left == volumeSlider.left,
                                    icloudDocButton.top == musPickerButton.top,
                                    icloudDocButton.centerX == albumTitleLabel.centerX,
                                    trackListButton.top == musPickerButton.top,
                                    trackListButton.right == volumeSlider.right,
                                    songTitleLabel.bottom == albumTitleLabel.top - 16,
                                    albumTitleLabel.leading == songTitleLabel.leading,
                                    albumTitleLabel.trailing == songTitleLabel.trailing,
                                    albumTitleLabel.bottom == playPauseButton.top - margin,
                                    playPauseButton.centerX == albumTitleLabel.centerX,
                                    nextTrackButton.leading == playPauseButton.trailing + margin,
                                    nextTrackButton.centerY == playPauseButton.centerY,
                                    prevTrackButton.trailing == playPauseButton.leading - margin,
                                    prevTrackButton.centerY == playPauseButton.centerY,
                                    volumeSlider.leading == albumTitleLabel.leading + margin,
                                    volumeSlider.trailing == albumTitleLabel.trailing - margin,
                                    volumeSlider.top == playPauseButton.bottom + 80,
                                    volumeSlider.height == volumeSlider.frame.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Play"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(ViewController.togglePlayback), for: .touchUpInside)
        
        nextTrackButton.setBackgroundImage(#imageLiteral(resourceName: "Next"), for: .normal)
        nextTrackButton.addTarget(self, action: #selector(ViewController.toggleNextTrack), for: .touchUpInside)
        
        prevTrackButton.setBackgroundImage(#imageLiteral(resourceName: "Prev"), for: .normal)
        prevTrackButton.addTarget(self, action: #selector(ViewController.togglePrevTrack), for: .touchUpInside)
        
        musPickerButton.setBackgroundImage(#imageLiteral(resourceName: "Music"), for: .normal)
        musPickerButton.addTarget(self, action: #selector(ViewController.presentMusicPicker), for: .touchUpInside)
        
        trackListButton.setBackgroundImage(#imageLiteral(resourceName: "List"), for: .normal)
        trackListButton.addTarget(self, action: #selector(ViewController.presentMusicQueueList), for: .touchUpInside)
        
        icloudDocButton.setBackgroundImage(#imageLiteral(resourceName: "Cloud"), for: .normal)
        icloudDocButton.addTarget(self, action: #selector(ViewController.presentCloudDocPicker), for: .touchUpInside)
        
        songTitleLabel.text = "Welcome to Treble"
        songTitleLabel.type = .continuous
        songTitleLabel.trailingBuffer = 16
        songTitleLabel.font = .preferredFont(forTextStyle: .title2)
        songTitleLabel.textAlignment = .center
        
        albumTitleLabel.text = "Play from your Apple Music library, or from your iCloud Drive."
        albumTitleLabel.type = .continuous
        albumTitleLabel.trailingBuffer = 16
        albumTitleLabel.font = .preferredFont(forTextStyle: .body)
        albumTitleLabel.textAlignment = .center
        
        self.setupMediaRemote()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateCurrentTrack), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updatePlaybackState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        musicPlayer.beginGeneratingPlaybackNotifications()
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        switch UIDevice.current.orientation {
        case .portrait:
            NSLayoutConstraint.deactivate(horizontalConstraints)
            NSLayoutConstraint.activate(verticalConstraints)
            self.containerConstraints!.top.constant = self.view.frame.height/12
            self.containerConstraints!.bottom.constant = 0.0
        case .landscapeLeft, .landscapeRight:
            NSLayoutConstraint.deactivate(verticalConstraints)
            NSLayoutConstraint.activate(horizontalConstraints)
            self.containerConstraints!.top.constant = min(self.view.frame.width, self.view.frame.height)/8
            self.containerConstraints!.bottom.constant = -min(self.view.frame.width, self.view.frame.height)/8
        default:
            break
        }
        super.updateViewConstraints()
    }
    
    func setupMediaRemote() {
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { _ in
            self.togglePlayback()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ in
            self.togglePlayback()
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { _ in
            self.togglePlayback()
            return .success
        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { _ in
            self.togglePrevTrack()
            return .success
        }
        
    }
    
    @objc func restartPlayback() {
        guard let _ = audioPlayer.currentItem else { return }
        audioPlayer.seek(to: kCMTimeZero)
        audioPlayer.play()
    }
    
    @objc func updateCurrentTrack() {
        switch musicType {
        case .file:
            trackListView.currentTrack = nil
            trackListButton.isEnabled = false
            guard let currentItem = self.audioPlayer.currentItem else { return }
            self.updatePlaybackState()
            var metadata: [MetadataKey: String] = [:]
            var albumImage: UIImage = #imageLiteral(resourceName: "DefaultAlbumArt")
            
            for format in currentItem.asset.availableMetadataFormats {
                for item in currentItem.asset.metadata(forFormat: format) where item.commonKey != nil {
                    switch item.commonKey! {
                    case .commonKeyArtist:
                        metadata[.artist] = item.value as? String
					case .commonKeyTitle:
                        metadata[.title] = item.value as? String
                    case .commonKeyAlbumName:
                        metadata[.albumTitle] = item.value as? String
                    case .commonKeyType:
                        metadata[.type] = item.value as? String
                    case .commonKeyCreator:
                        metadata[.creator] = item.value as? String
                    case .commonKeyArtwork:
                        guard let data: Data = item.value as? Data, let image = UIImage(data: data) else { continue }
                        albumImage = image
                    default:
                        print("no-tag", item.commonKey!)
                    }
                }
            }
            
            self.songTitleLabel.text = metadata[.title] ?? audioFileName ?? ""
            let artistName = metadata[.artist] ?? audioArtistName ?? ""
            let albumTitle = metadata[.albumTitle] ?? ""
            self.albumTitleLabel.text = albumTitle.isEmpty ? artistName : (albumTitle + (!artistName.isEmpty ? " – \(artistName)" : ""))
            self.updateAlbumImage(to: albumImage)
            
            var nowPlayingInfo: [String: Any] = [:]
            nowPlayingInfo[MPMediaItemPropertyTitle] = metadata[.title] ?? audioFileName!
            nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentItem.asset.duration.seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1)
            
            if #available(iOS 10.0, *) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: albumImage.size) { return albumImage.resize($0) }
            } else {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: albumImage)
            }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
        case .library:
            guard let songItem = musicPlayer.nowPlayingItem else { return }
            trackListView.currentTrack = songItem
            trackListButton.isEnabled = true
            self.updatePlaybackState()
            self.songTitleLabel.text = songItem.title
            self.albumTitleLabel.text = "\(songItem.artist!) — \(songItem.albumTitle!)"
            guard let artwork = songItem.artwork, let image = artwork.image(at: self.view.frame.size) else { return }
            self.updateAlbumImage(to: image)
        }
        
        self.albumTitleLabel.restartLabel()
        self.songTitleLabel.restartLabel()
        
    }
    
    func updateAlbumImage(to image: UIImage?) {
        let image = image ?? #imageLiteral(resourceName: "DefaultAlbumArt")
        let isDarkColor = image.averageColor.isDark
        let blurEffect = isDarkColor ? UIBlurEffect(style: .light) : UIBlurEffect(style: .dark)
        UIView.animate(withDuration: 0.5) {
            self.imageInnerView.image = image
            self.backgroundImageView.image = image
            self.backgroundView.effect = blurEffect
            self.vibrancyEffectView.effect = UIVibrancyEffect(blurEffect: blurEffect)
            self.volumeSlider.tintColor = image.averageColor
        }
    }
    
    @objc func togglePlayback() {
        switch musicType {
        case .library:
            guard let _ = musicPlayer.nowPlayingItem else { return }
            switch musicPlayer.playbackState {
            case .playing: musicPlayer.pause()
            case .paused:  musicPlayer.play()
            default:       break
            }
        case .file:
            guard let _ = audioPlayer.currentItem else { return }
            if audioPlayer.rate == 0 {
                audioPlayer.play()
            } else {
                audioPlayer.pause()
            }
        }
        self.updatePlaybackState()
    }
    
    @objc func updatePlaybackState() {
        switch musicType {
        case .library:
            switch musicPlayer.playbackState {
            case .playing: playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            case .paused:  playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Play"),  for: .normal)
            default:       break
            }
            self.updateAlbumImageConstraints(for: musicPlayer.playbackState)
        case .file:
            if audioPlayer.rate == 0 { // is paused
                playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Play"),  for: .normal)
                self.updateAlbumImageConstraints(for: .paused)
            } else {
                playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Pause"), for: .normal)
                self.updateAlbumImageConstraints(for: .playing)
            }
        }
    }
    
    func updateAlbumImageConstraints(for playingState: MPMusicPlaybackState) {
        DispatchQueue.main.async {
            let constant: CGFloat = playingState == .paused ? 8 : 0
            self.albumImageConstraints.left.constant = constant
            self.albumImageConstraints.right.constant = -constant
            self.albumImageConstraints.top.constant = constant
            self.albumImageConstraints.bottom.constant = -constant
            UIView.animate(withDuration: 0.25) {
                self.imageOuterView.layoutIfNeeded()
            }
        }
    }
    
    @objc func toggleNextTrack() {
        guard let _ = musicPlayer.nowPlayingItem else { return }
        musicPlayer.skipToNextItem()
    }
    
    @objc func togglePrevTrack() {
        switch musicType {
        case .library:
            guard let _ = musicPlayer.nowPlayingItem else { return }
            if musicPlayer.currentPlaybackTime < 5.0 {
                musicPlayer.skipToPreviousItem()
            } else {
                musicPlayer.skipToBeginning()
            }
        case .file:
            guard let _ = audioPlayer.currentItem else { return }
            audioPlayer.seek(to: kCMTimeZero)
            self.updateCurrentTrack()
        }
        
    }
    
    @objc func presentMusicQueueList() {
        guard let _ = trackListView.currentTrack, !trackListView.trackList.isEmpty else { return }
        let viewController = UINavigationController(rootViewController: trackListView)
        viewController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .popover : .custom
        viewController.popoverPresentationController?.backgroundColor = .clear
        viewController.popoverPresentationController?.sourceView = trackListButton
        viewController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: trackListButton.frame.height/2, width: 0, height: 0)
        viewController.popoverPresentationController?.permittedArrowDirections = .any
        viewController.transitioningDelegate = trackListView
        self.present(viewController, animated: true, completion: nil)
    }
    
    @objc func presentMusicPicker() {
        let musicPickerViewController = MPMediaPickerController(mediaTypes: .anyAudio)
        musicPickerViewController.delegate = self
        musicPickerViewController.allowsPickingMultipleItems = true
        musicPickerViewController.showsCloudItems = true
        self.present(musicPickerViewController, animated: true, completion: nil)
    }
    
    @objc func presentCloudDocPicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }

}

extension ViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        self.musicPlayer.setQueue(with: mediaItemCollection)
        mediaPicker.dismiss(animated: true) {
            self.musicPlayer.play()
            self.musicType = .library
            self.updateCurrentTrack()
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController: UIDocumentPickerDelegate {

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard controller.documentPickerMode == .import else { return }
        let audioItem = AVPlayerItem(url: UIDocument(fileURL: url).presentedItemURL!)
        let url = url.deletingPathExtension()
        let fullName = url.lastPathComponent
        if fullName.components(separatedBy: "-").count == 2 {
            let components = fullName.components(separatedBy: "-")
            audioArtistName = components[0]
            audioFileName = components[1]
        } else {
            audioFileName = fullName
        }
        
        self.musicType = .file
        self.audioPlayer = AVPlayer(playerItem: audioItem)
        self.audioPlayer.play()
        
        self.updateCurrentTrack()
    }
    
}
