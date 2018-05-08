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
    private let songTimeLabel = UILabel()
    
    private let backgroundImageView = UIImageView()
    private var backgroundView: UIVisualEffectView!
    private var vibrancyEffectView: UIVisualEffectView!
    
    private let playPauseButton = UIButton(type: .custom)
    private let nextTrackButton = UIButton(type: .custom)
    private let prevTrackButton = UIButton(type: .custom)
    private let musPickerButton = UIButton(type: .custom)
    private let trackListButton = UIButton(type: .custom)
    
    fileprivate let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    fileprivate var audioPlayer: AVPlayer!
    fileprivate var audioFileName: String?
    fileprivate var audioArtistName: String?
    
    fileprivate var playerTimer : Timer? = nil {
        willSet { playerTimer?.invalidate() }
    }
    
    fileprivate var musicType: MusicType = .library {
        didSet {
            do {
                switch musicType {
                case .file:
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    UIApplication.shared.beginReceivingRemoteControlEvents()
                    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.restartFilePlayback), name: .AVPlayerItemDidPlayToEndTime, object: nil)
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
    
    private var autoLoadMode: Bool = true;
    
    private let volumeSlider: MPVolumeView = MPVolumeView()
    
    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []
    private var containerConstraints: (top: NSLayoutConstraint, bottom: NSLayoutConstraint)!
    private var albumImageConstraints: (left: NSLayoutConstraint, right: NSLayoutConstraint, top: NSLayoutConstraint, bottom: NSLayoutConstraint)!
    
    private lazy var trackListView: TrackListViewController = TrackListViewController()
    
    override var prefersStatusBarHidden: Bool { return false } // status bar hidden?
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent  } //status bar color // .default
    
    
    // VIEW CONTROLLER FUNCTIONS /////////////////////////////////////////////////////////////////
    
    override func loadView() {
        super.loadView()
        
        let blurEffect = UIBlurEffect(style: .dark)
        backgroundView = UIVisualEffectView(effect: blurEffect)
        vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        vibrancyEffectView.backgroundColor = UIColor(white: 1.0, alpha: 0.05) //reduces vibrancy transparency fast (~0.2) but makes text more legible
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.backgroundColor = .white
        
        volumeSlider.showsRouteButton = false // Airplay etc.
        volumeSlider.sizeToFit()
        
        imageOuterView.backgroundColor = .clear
        imageInnerView.isUserInteractionEnabled = true //essential for tap
        imageInnerView.contentMode = .scaleAspectFill
        imageInnerView.layer.cornerRadius = 13.0 //12
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
        vibrancyEffectView.contentView.addSubview(songTimeLabel)
        vibrancyEffectView.contentView.addSubview(playPauseButton)
        vibrancyEffectView.contentView.addSubview(prevTrackButton)
        vibrancyEffectView.contentView.addSubview(nextTrackButton)
        vibrancyEffectView.contentView.addSubview(trackListButton)
        
        let views: [UIView] = [containerView, backgroundImageView, backgroundView, vibrancyEffectView, imageOuterView, imageInnerView, musPickerButton, volumeSlider, songTitleLabel, albumTitleLabel, songTimeLabel, playPauseButton, prevTrackButton, nextTrackButton, trackListButton]
        
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
            imageOuterView.width == containerView.width * 0.76,
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
        
        let buttonSize: CGFloat = 48.0, margin: CGFloat = 24.0, smallButtonSize: CGFloat = 36.0
        
        musPickerButton.constrainSize(to: smallButtonSize)
        trackListButton.constrainSize(to: smallButtonSize)
        playPauseButton.constrainSize(to: buttonSize)
        prevTrackButton.constrainSize(to: buttonSize)
        nextTrackButton.constrainSize(to: buttonSize)
        
        NSLayoutConstraint.activate(imageInnerView.width <= imageOuterView.width,
                                    imageInnerView.height <= imageOuterView.height,
                                    
                                    musPickerButton.bottom == volumeSlider.top - 16,
                                    musPickerButton.left == volumeSlider.left,
                                    
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
                                    
                                    songTimeLabel.centerX == albumTitleLabel.centerX,
                                    songTimeLabel.top == musPickerButton.top,
                                    songTimeLabel.bottom == musPickerButton.bottom,
                                    songTimeLabel.width == albumTitleLabel.width * 0.5,
                                    
                                    
                                    volumeSlider.leading == albumTitleLabel.leading + margin,
                                    volumeSlider.trailing == albumTitleLabel.trailing - margin,
                                    volumeSlider.top == playPauseButton.bottom + 80,
                                    volumeSlider.height == volumeSlider.frame.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Buttons
        playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Play"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(ViewController.togglePlayback), for: .touchUpInside)
        
        nextTrackButton.setBackgroundImage(#imageLiteral(resourceName: "Next"), for: .normal)
        nextTrackButton.addTarget(self, action: #selector(ViewController.toggleNextTrack), for: .touchUpInside)
        
        prevTrackButton.setBackgroundImage(#imageLiteral(resourceName: "Prev"), for: .normal)
        prevTrackButton.addTarget(self, action: #selector(ViewController.togglePrevTrack), for: .touchUpInside)
        
        musPickerButton.setBackgroundImage(#imageLiteral(resourceName: "Music"), for: .normal)
        musPickerButton.addTarget(self, action: #selector(ViewController.presentMusicPicker), for: .touchUpInside)
        updateMusicPickerButton() //Guided Access hiding function
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateMusicPickerButton), name: NSNotification.Name.UIAccessibilityGuidedAccessStatusDidChange, object: nil)
        
        trackListButton.setBackgroundImage(#imageLiteral(resourceName: "List"), for: .normal)
        trackListButton.addTarget(self, action: #selector(ViewController.presentMusicQueueList), for: .touchUpInside)
        updateTrackListButton(enabled: false)
        
        let albumImageTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.togglePlayback))
        albumImageTap.numberOfTapsRequired = 2 //double tap
        imageInnerView.addGestureRecognizer(albumImageTap)
        imageInnerView.isUserInteractionEnabled = true
        
        
        // Text Labels
        songTitleLabel.text = "Welcome to Treble"
        songTitleLabel.type = .continuous
        songTitleLabel.trailingBuffer = 16
        songTitleLabel.font = .preferredFont(forTextStyle: .title2)
        songTitleLabel.textAlignment = .center
        
        albumTitleLabel.text = "Please add from your Music library!"
        albumTitleLabel.type = .continuous
        albumTitleLabel.trailingBuffer = 16
        albumTitleLabel.font = .preferredFont(forTextStyle: .body)
        albumTitleLabel.textAlignment = .center
        
        songTimeLabel.text = "0:00 / 0:00"
        songTimeLabel.font = .preferredFont(forTextStyle: .body)
        songTimeLabel.textAlignment = .center
        
        
        // Remote controls from earpods etc
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
        
        
        // Music Player Callbacks
       
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateCurrentTrack), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updatePlaybackState), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.runEveryTimeAppReopens), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    @objc func runEveryTimeAppReopens() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.assertMusicPlayerSettings() // reset to noShuffle and repeatAll
            self.autoLoadPlaylist()          // start on Treble playlist
            self.updateSongTime(force: true) // force because update usually skips the update if we are .paused to save processing energy
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        playerTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(ViewController.updateSongTime), userInfo: nil, repeats: true)
        playerTimer!.tolerance = 0.1
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
    
    
    
    // MUSIC PLAYER FUNCTIONS ////////////////////////////////////////////////////////////////////
    
    func autoLoadPlaylist() {
        guard autoLoadMode else { return }
        
        let query = MPMediaQuery.playlists()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: "Treble", forProperty: MPMediaPlaylistPropertyName))
        if let playlists = query.collections {
            guard !playlists.isEmpty else { NSLog("Treble Playlist Not Found, will not try again."); autoLoadMode = false; return }
            //print(playlists[0].value(forProperty: MPMediaPlaylistPropertyName)!)
            
            guard playlists[0].count > 0 else { NSLog("Treble Playlist Empty, will not try again."); autoLoadMode = false; return }
            musicType = .library
            musicPlayer.stop()
            musicPlayer.setQueue(with: playlists[0])
            trackListView.setQueue(with: playlists[0])
            musicPlayer.nowPlayingItem = playlists[0].items[0]
            updateCurrentTrack()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.musicPlayer.play()
            }
        }
    }
    
    func clearTrackandQueue() {
        // TODO clear function
        // reset tracklist, buttons, album art, text labels, and hide tracklist button
        
        musicPlayer.stop();
        
        songTitleLabel.text = "Welcome to Treble"
        albumTitleLabel.text = "Please add from your Music library!"
        songTimeLabel.text = "0:00 / 0:00";
        updateTrackListButton(enabled: false)
        
        updateAlbumImage();
    }
    
    @objc func updateCurrentTrack() {
        switch musicType {
        case .file:
            trackListView.currentTrack = nil
            updateTrackListButton(enabled: false)
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
            guard let songItem = musicPlayer.nowPlayingItem else { clearTrackandQueue(); return }
            trackListView.currentTrack = songItem;
            updateTrackListButton(enabled: true)
            
            self.updatePlaybackState()
            self.songTitleLabel.text = songItem.title
            self.albumTitleLabel.text = "\(songItem.artist!) — \(songItem.albumTitle!)"
            guard let artwork = songItem.artwork, let image = artwork.image(at: self.view.frame.size) else { return }
            self.updateAlbumImage(to: image)
            
        }
        
        self.albumTitleLabel.restartLabel()
        self.songTitleLabel.restartLabel()
        
        self.assertMusicPlayerSettings()
        self.updateSongTime(force: true)
    }
    
    func updateAlbumImage(to image: UIImage? = #imageLiteral(resourceName: "DefaultAlbumArt")) {
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
    
    @objc func updateSongTime(force: Bool = false) {

        switch musicType {
        case .library:
            if (self.musicPlayer.playbackState != .playing && !force) { return }
            guard let songItem = musicPlayer.nowPlayingItem else { clearTrackandQueue(); return }
            
            let trackDuration = songItem.playbackDuration
            let trackElapsed = musicPlayer.currentPlaybackTime
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            
            if (trackDuration >= 86400) {
                formatter.allowedUnits = [.day, .hour, .minute, .second]
            } else if (trackDuration >= 3600) {
                formatter.allowedUnits = [.hour, .minute, .second]
            } else {
                formatter.allowedUnits = [.minute, .second]
            }
            
            let elapsedStr = formatter.string(from: trackElapsed)!
            let durationStr = formatter.string(from: trackDuration)!
            songTimeLabel.text = "\(elapsedStr) / \(durationStr)"
        
        
        case .file:
            if (audioPlayer.rate == 0  && !force) { return }
            // handle later? only for icloud
            songTimeLabel.text = "error, unhandled"
        }

    }
    
    @objc func togglePlayback() {
        switch musicType {
        case .library:
            guard let _ = musicPlayer.nowPlayingItem else { clearTrackandQueue(); return }
            switch musicPlayer.playbackState {
            case .playing: musicPlayer.pause();
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
            case .paused, .stopped:  playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Play"),  for: .normal)
            default:       break
            }
            self.updateAlbumImageConstraintsAndOpacity(for: musicPlayer.playbackState)
        case .file:
            if audioPlayer.rate == 0 { // is paused
                playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Play"),  for: .normal)
                self.updateAlbumImageConstraintsAndOpacity(for: .paused)
            } else {
                playPauseButton.setBackgroundImage(#imageLiteral(resourceName: "Pause"), for: .normal)
                self.updateAlbumImageConstraintsAndOpacity(for: .playing)
            }
        }
    }
    
    @objc func assertMusicPlayerSettings() {
        musicPlayer.repeatMode = .all
        musicPlayer.shuffleMode = .off
    }
    
    @objc func toggleNextTrack() {
        guard let _ = musicPlayer.nowPlayingItem else { clearTrackandQueue(); return }
        assertMusicPlayerSettings()
        musicPlayer.skipToNextItem()
    }
    
    @objc func togglePrevTrack() {
        switch musicType {
        case .library:
            guard let _ = musicPlayer.nowPlayingItem else { clearTrackandQueue(); return }
            assertMusicPlayerSettings()
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
    
    @objc func restartFilePlayback() {
        guard let _ = audioPlayer.currentItem else { return }
        audioPlayer.seek(to: kCMTimeZero)
        audioPlayer.play()
    }
    
    
    
    // TRANSITIONS AND VIEW CHANGES ////////////////////////////////////////////
    
    func updateAlbumImageConstraintsAndOpacity(for playingState: MPMusicPlaybackState) { // sound reactive here if you need!
        DispatchQueue.main.async {
            let constant: CGFloat = playingState == .paused ? 40 : 0
            self.albumImageConstraints.left.constant = constant
            self.albumImageConstraints.right.constant = -constant
            self.albumImageConstraints.top.constant = constant
            self.albumImageConstraints.bottom.constant = -constant
            
            let alpha: CGFloat = playingState == .paused ? 0.4 : 1
            
            UIView.animate(withDuration: 0.25) {
                self.imageOuterView.alpha = alpha
                self.imageOuterView.layoutIfNeeded()
            }
        }
    }
    
    @objc func presentMusicQueueList() {
        guard let _ = trackListView.currentTrack, !trackListView.trackList.isEmpty else { return }
        let viewController = UINavigationController(rootViewController: trackListView)
        viewController.modalPresentationStyle = .popover //UIDevice.current.userInterfaceIdiom == .pad ? .popover : .custom
        viewController.popoverPresentationController?.backgroundColor = .clear
        viewController.popoverPresentationController?.sourceView = imageInnerView //used to be trackListButton
        viewController.popoverPresentationController?.sourceRect = CGRect(x: imageInnerView.bounds.midX, y: imageInnerView.bounds.midY+7, width: 0, height: 0) // 5 mystery pixels for arrow offset?
        viewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0) //center on source

        viewController.preferredContentSize = CGSize(width: imageInnerView.bounds.width, height: imageInnerView.bounds.height-44) // match to imageInnerView, 40 mystery pixels
//        viewController.setNavigationBarHidden(true, animated: false)
        viewController.transitioningDelegate = trackListView
        self.present(viewController, animated: true, completion: nil)
    }
    
    @objc func presentMusicPicker() {
        let musicPickerViewController = MPMediaPickerController(mediaTypes: .anyAudio)
        musicPickerViewController.delegate = self
        musicPickerViewController.allowsPickingMultipleItems = true
        musicPickerViewController.showsCloudItems = false //true
        self.present(musicPickerViewController, animated: true, completion: nil)
    }
    
    @objc func updateMusicPickerButton() {
        self.musPickerButton.isEnabled = !UIAccessibilityIsGuidedAccessEnabled()
    }
    
    @objc func updateTrackListButton(enabled: Bool) {
        if trackListView.isQueueEmpty() { trackListButton.isEnabled = false; return }
        trackListButton.isEnabled = enabled
    }
    
}




extension ViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true) {
            self.autoLoadMode = false
            self.musicType = .library
            self.musicPlayer.stop()
            self.musicPlayer.setQueue(with: mediaItemCollection)
            self.trackListView.setQueue(with: mediaItemCollection)
            self.musicPlayer.nowPlayingItem = mediaItemCollection.items[0]
            self.updateCurrentTrack()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.musicPlayer.play()
            }
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
}


