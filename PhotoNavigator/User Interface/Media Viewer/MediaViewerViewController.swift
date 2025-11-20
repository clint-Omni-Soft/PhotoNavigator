//
//  MediaViewerViewController.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 8/7/24.
//

import Photos
import UIKit
import WebKit



protocol MediaViewerViewControllerDelegate: Any {
    func mediaViewerViewController(_ mediaViewerVC: MediaViewerViewController, didShowMediaAt indexPath: IndexPath )
}


class MediaViewerViewController: UIViewController {
    
    
    // MARK: Public Definitions
    
    var delegate: MediaViewerViewControllerDelegate!

    @IBOutlet weak var mediaNameLabel        : UILabel!
    @IBOutlet weak var myActivityIndicator   : UIActivityIndicatorView!
    @IBOutlet weak var myImageView           : UIImageView!
    @IBOutlet weak var myWebView             : WKWebView!
    @IBOutlet      var panGestureRecognizer  : UIPanGestureRecognizer!
    @IBOutlet      var pinchGestureRecognizer: UIPinchGestureRecognizer!
    
    
    // MARK: Public Interfaces
    
    func displayAssetAt(_ indexPath: IndexPath, _ delegate: MediaViewerViewControllerDelegate ) {
        self.delegate     = delegate
        deviceAsset       = navigatorCentral.deviceAssetAt( indexPath )
        presentingAssets  = true
        resourceIndexPath = indexPath
        
        logVerbose( "[ %@ ][ %@ ]", stringFor( indexPath ), deviceAsset.descriptorString() )
        
        requestAssetData()
        loadBarButtonItems()
    }
    
    
    func displayMediaFileAt(_ indexPath: IndexPath, _ delegate: MediaViewerViewControllerDelegate ) {
        self.delegate     = delegate
        mediaFile         = navigatorCentral.mediaFileAt( indexPath )
        presentingAssets  = false
        resourceIndexPath = indexPath

        logVerbose( "[ %@ ][ %@ ]", stringFor( indexPath ), mediaFile.filename! )
        
        requestMediaFileData()
        loadBarButtonItems()
    }
    
    
    func primaryWindow(_ isHidden: Bool ) {
        logVerbose( "isHidden[ %@ ]", stringFor( isHidden ) )
        primaryWindowIsHidden = isHidden
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            if let _ = self.playerLayer {
                // Since myImageView has constraints on it that will automatically reposition and resize itself,
                // we attach the playerLayer to it so it can just tag along for the ride
                self.playerLayer.frame = self.myImageView.layer.bounds
            }
            
            self.loadBarButtonItems()
        }
        
    }
    
    
    
    // MARK: Private Variables
    
    private let appDelegate             = UIApplication.shared.delegate as! AppDelegate
    private var application             = UIApplication.shared
    private let cachingImageManager     = PHCachingImageManager()
    private var connectedShare          : SMBShare!
    private var currentVideoUrl         : URL!
    private let deviceAccessControl     = DeviceAccessControl.sharedInstance
    private var deviceAsset             : PHAsset!
    private var documentDirctoryUrl     : URL!
    private var fileData                : Data!
    private let fileManager             = FileManager.default
    private let imageManager            = PHImageManager.default()
    private var loadingData             = true
    private var mediaFile               : MediaFile!
    private let nasCentral              = NASCentral.sharedInstance
    private let navigatorCentral        = NavigatorCentral.sharedInstance
    private let notificationCenter      = NotificationCenter.default
    private var picturesDirectoryUrl    : URL!
    private var playerLayer             : AVPlayerLayer!
    private var presentingAssets        = false
    private var primaryWindowIsHidden   = false
    private var requestPending          = false
    private var resourceIndexPath       = GlobalIndexPaths.noSelection
    private var nasSessionActive        = false
    private var slideShowActive         = false
    private var slideShowTimer          : Timer!
    private var videoStateBacking       = VideoState.notLoaded

    
    private enum VideoState {
        case notLoaded
        case loaded
        case playing
        case paused
    }
    
    
    private var videoState: VideoState {
        get {
            return videoStateBacking
        }
        
        set (newState) {
            videoStateBacking = newState
            loadBarButtonItems()
        }
        
    }
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.MediaViewer",       comment: "Media Viewer"    )
        mediaNameLabel.text  = NSLocalizedString( "LabelText.NoMediaLoaded", comment: "No Media Loaded" )

        hideControls()

        myImageView.isUserInteractionEnabled = true

        myWebView.allowsBackForwardNavigationGestures = false
        myWebView.contentMode        = .scaleAspectFit
        myWebView.navigationDelegate = self

        appDelegate.mediaViewer = self

        guard let baseUrl = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }

        documentDirctoryUrl  = baseUrl
        picturesDirectoryUrl = documentDirctoryUrl.appendingPathComponent( DirectoryNames.pictures )

        let _ = emptyVideoCache()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
        registerForNotifications()
        
        // When we are on the iPhone, we can transition to another tab.
        // Make sure we don't blow away what we were displaying when we return
        if !myImageView.isHidden || !myWebView.isHidden {
            playVideo()
        }
        else {
            mediaNameLabel.text  = NSLocalizedString( "LabelText.NoMediaLoaded", comment: "No Media Loaded" )
            myImageView.isHidden = true
            
            hideControls()
            
            if requestPending {
                requestPending = false
                
                if presentingAssets {
                    requestAssetData()
                }
                else {
                    requestMediaFileData()
                }
                
            }
            
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        
        nasSessionActive = false
        slideShowActive  = false

        disableImageSlideShowTimer()

        if playerLayer != nil {
            playerLayer.player?.pause()
            videoState = .paused
        }
        
        notificationCenter.removeObserver( self )
    }
    
    
    override func viewWillTransition( to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator ) {
//        logVerbose( "[ %@ ]", stringFor( size ) )
        super.viewWillTransition( to: size, with: coordinator )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            if let _ = self.playerLayer {
                // Since myImageView has constraints on it that will automatically reposition and resize itself,
                // we attach the playerLayer to it so it can just tag along for the ride
                self.playerLayer.frame = self.myImageView.layer.bounds
            }
            
            if !self.primaryWindowIsHidden {
                self.primaryWindowIsHidden = UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown
            }
            
        }
        
    }
    
    
    
    // MARK: Notification Methods
    
    @objc func enteringBackground( notification: NSNotification ) {
        logTrace()
        // The playerLayer is attached to myImageView when a video is loaded.
        if !myImageView.isHidden && playerLayer != nil {
            playerLayer.player!.pause()
            
            slideShowActive = false
            videoState      = .paused
        }
        
    }
    
    
    @objc func mediaDataReloaded( notification: NSNotification ) {
        logTrace()
        mediaNameLabel.text = NSLocalizedString( "LabelText.NoMediaLoaded", comment: "No Media Loaded" )
        resetViews()
    }


    @objc func playerDidFinishPlayingVideo( notification: NSNotification ) {
        logVerbose( "slideShowActive[ %@ ]", stringFor( slideShowActive ) )
        cleanUpPlayer()
        hideControls()

        if slideShowActive {
            if presentingAssets {
                requestNextAsset( forward: true )
            }
            else {
                requestNextMediaFile( forward: true )
            }
            
            delegate.mediaViewerViewController( self, didShowMediaAt: self.resourceIndexPath )
        }

    }
    
    
    
    // MARK: Target/Action Methods
    @IBAction func panGestureRecognizerTouched(_ gestureRecognizer: UIPanGestureRecognizer ) {
        if !slideShowActive && ( gestureRecognizer.state == .began || gestureRecognizer.state == .changed ) {
            let translation = gestureRecognizer.translation(in: myImageView )
            
            gestureRecognizer.view?.layer.setAffineTransform( ( gestureRecognizer.view?.transform.translatedBy(x: translation.x, y: translation.y ) )! )
        }
        
        gestureRecognizer.setTranslation( CGPoint.zero, in: gestureRecognizer.view )
    }
    
    
    @IBAction func pinchGestureRecognizerTouched(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if !slideShowActive && ( gestureRecognizer.state == .began || gestureRecognizer.state == .changed ) {
            gestureRecognizer.view?.transform = ( gestureRecognizer.view?.transform.scaledBy( x: gestureRecognizer.scale, y: gestureRecognizer.scale ) )!
        }
        
        gestureRecognizer.scale = 1.0
    }
    
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let message = NSLocalizedString( "InfoText.MediaViewer1", comment: "When a photo is presented, 3 buttons will appear at the top to control the slide show.  A double back caret will go back one photo followed by a start/stop icon to start/stop the slide show and a double forward cart to go forward on photo.\n\n" )
                    + NSLocalizedString( "InfoText.MediaViewer2", comment: "When a video is presented, a button will appear on the left to pause/resume playing the video.  \n\nWhen on the iPad, a 'hamburger' icon will appear that will allow you to display the Photo list view." )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }
    
    
    @IBAction func showPrimaryBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( false )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            if let _ = self.playerLayer {
                // Since myImageView has constraints on it that will automatically reposition and resize itself,
                // we attach the playerLayer to it so it can just tag along for the ride
                self.playerLayer.frame = self.myImageView.layer.bounds
            }
            
        }
        
    }
    
    
    @IBAction func slideShowSkipBackwardBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        cleanUpPlayer()
        hideControls()
        disableImageSlideShowTimer()
        
        if presentingAssets {
            requestNextAsset( forward: false )
        }
        else {
            requestNextMediaFile( forward: false )
        }
        
        delegate.mediaViewerViewController( self, didShowMediaAt: resourceIndexPath )
    }
    
    
    @IBAction func slideShowSkipForwardBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        cleanUpPlayer()
        hideControls()
        disableImageSlideShowTimer()
        loadBarButtonItems()
        
        if presentingAssets {
            requestNextAsset( forward: true )
        }
        else {
            requestNextMediaFile( forward: true )
        }
        
        delegate.mediaViewerViewController( self, didShowMediaAt: resourceIndexPath )
    }
    
    
    @IBAction func slideShowStartStopBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        slideShowActive                 = !slideShowActive
        application.isIdleTimerDisabled =  slideShowActive
        loadBarButtonItems()
        
        if slideShowActive {
            appDelegate.hidePrimaryView( true )
            
            if playerLayer == nil {
                startImageSlideShowTimer()
            }
            else {
                playerLayer.player?.play()
                videoState = .playing
            }
            
        }
        else {
            appDelegate.hidePrimaryView( false )
            disableImageSlideShowTimer()
            
            if playerLayer != nil {
                playerLayer.player?.pause()
                videoState = .paused
           }
            
        }
        
    }
    
    
    @IBAction func videoStartStopButtonTouched(_ sender: UIButton) {
        logTrace()
        if videoState == .paused || videoState == .loaded {
            playVideo()
        }
        else {
            playerLayer.player?.pause()
            videoState = .paused
        }
        
        loadBarButtonItems()
    }
    
    

    // MARK: Utility Methods
    
    private func cleanUpPlayer() {
        logTrace()
        if let _ = playerLayer {
            playerLayer.removeFromSuperlayer()
            playerLayer = nil
            videoState  = .notLoaded
            
            if !presentingAssets && !emptyVideoCache() {
                logTrace( "ERROR!!!  Need cleanup on aisle #9!" )
            }
            
        }
        
    }
    
    
    private func hideControls() {
        myActivityIndicator.isHidden = true
        myImageView        .isHidden = true
        myWebView          .isHidden = true
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        var leftBarButtonItems : [UIBarButtonItem] = []
        var rightBarButtonItems: [UIBarButtonItem] = []
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            leftBarButtonItems.append( UIBarButtonItem.init(image: UIImage(named: "hamburger" ), style: .plain, target: self, action: #selector( showPrimaryBarButtonItemTouched(_:) ) ) )
        }
        
        if videoState != .notLoaded {
            let videoBarButtonImage = ( videoState == .playing ) ? UIImage(named: "pauseVideo" ) : UIImage(named: "playVideo" )

            leftBarButtonItems.append( UIBarButtonItem.init(image: videoBarButtonImage, style: .plain, target: self, action: #selector( videoStartStopButtonTouched(_:) ) ) )
        }
        
        leftBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) ) )

        if resourceIndexPath != GlobalIndexPaths.noSelection {
            let slideShowButton: UIBarButtonItem.SystemItem = slideShowActive ? .pause : .play
            
            rightBarButtonItems.append( UIBarButtonItem.init(barButtonSystemItem: .fastForward,    target: self, action: #selector( slideShowSkipForwardBarButtonTouched(_  :) ) ) )
            rightBarButtonItems.append( UIBarButtonItem.init(barButtonSystemItem: slideShowButton, target: self, action: #selector( slideShowStartStopBarButtonTouched(_    :) ) ) )
            rightBarButtonItems.append( UIBarButtonItem.init(barButtonSystemItem: .rewind,         target: self, action: #selector( slideShowSkipBackwardBarButtonTouched(_ :) ) ) )
        }
        
        navigationItem.leftBarButtonItems  = leftBarButtonItems
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    
    private func playVideo() {
        // The playerLayer is attached to myImageView when a video is loaded.
        // In viewWillDisappear() we pause the video and remove ourselves as an observer
        if playerLayer != nil {
            playerLayer.player!.play()
            videoState = .playing
            
            notificationCenter.addObserver( self, selector: #selector( self.playerDidFinishPlayingVideo( notification: ) ),
                                            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerLayer.player!.currentItem )
        }

    }
    
    
    private func registerForNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( enteringBackground( notification: ) ), name: NSNotification.Name( rawValue: Notifications.enteringBackground ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( mediaDataReloaded(  notification: ) ), name: NSNotification.Name( rawValue: Notifications.mediaDataReloaded  ), object: nil )
    }
    
    
    private func resetViews() {
        logTrace()
        if playerLayer != nil {
            logTrace( "playerLayer != nil" )
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            videoState  = .notLoaded
        }

        myImageView.image     = nil
        myImageView.transform = .identity

        hideControls()
    }
    
    
}
    
    
    
    // MARK: Asset Methods
    
extension MediaViewerViewController {
            
    private func requestAssetData() {
        logTrace()
        resetViews()
        disableImageSlideShowTimer()
        
        mediaNameLabel.text = deviceAsset.descriptorString()

        if deviceAsset.mediaType == .image {
            var firstSegmentLoaded  = false
            let imageRequestOptions = PHImageRequestOptions()
            let scale               = UIScreen.main.scale
            let targetSize          = CGSize( width: myImageView.bounds.width * scale, height: myImageView.bounds.height * scale )
            
            imageRequestOptions.isNetworkAccessAllowed = false
            
            cachingImageManager.requestImage(for: deviceAsset, targetSize: targetSize, contentMode: .aspectFill, options: imageRequestOptions, resultHandler: { image, _ in
                self.myImageView.image    = image
                self.myImageView.isHidden = false
                
                if !firstSegmentLoaded {
                    firstSegmentLoaded = true
                }
                else {
//                    logTrace( "image loaded" )
                    
                    if self.slideShowActive {
                        self.startImageSlideShowTimer()
                    }
                    
                }
                
            })
            
        }
        else if deviceAsset.mediaType == .video {
            loadVideoFromAsset()
        }
        else {
            logVerbose( "ERROR!!! We don't support this style[ %@ ]", deviceAsset.stringForPlaybackStyle() )
        }
        
    }
    
    
    
    // MARK: Asset Utility Methods
    
    private func loadVideoFromAsset() {
        logTrace()
        let videoRequestOptions = PHVideoRequestOptions()
        
        videoRequestOptions.deliveryMode           = .automatic
        videoRequestOptions.isNetworkAccessAllowed = false
        
        imageManager.requestPlayerItem(forVideo: deviceAsset, options: videoRequestOptions, resultHandler: { playerItem, info in
            // Create an AVPlayer and AVPlayerLayer with the AVPlayerItem.
            let player      = AVPlayer(  playerItem: playerItem )
            let playerLayer = AVPlayerLayer( player: player     )
            
            // Since myImageView has constraints on it that will automatically reposition and resize itself,
            // we attach the playerLayer to it so it can just tag along for the ride
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            playerLayer.frame        = self.myImageView.layer.bounds
            
            self.myImageView.layer.addSublayer( playerLayer )
            self.myImageView.isHidden = false

            self.playerLayer = playerLayer
            self.videoState  = .loaded
            
            if self.slideShowActive {
                self.playVideo()
            }

        })
        
    }
    
    
    private func requestNextAsset( forward: Bool ) {
        if navigatorCentral.stayInFolder {
            if navigatorCentral.shuffleImages {
                resourceIndexPath = navigatorCentral.nextShuffledAssetFile( resourceIndexPath )
            }
            else {
                let currentSection = resourceIndexPath.section
                
                resourceIndexPath = navigatorCentral.nextAssetAfter( resourceIndexPath )
                
                if resourceIndexPath.section != currentSection {
                    resourceIndexPath.section = currentSection
                    resourceIndexPath.item    = 0
                }
                
            }
            
            logVerbose( "stayInFolder[ true ]  shuffleImages[ %@ ] -> resourceIndexPath[ %@ ]", stringFor( navigatorCentral.shuffleImages ), stringFor( resourceIndexPath ) )
        }
        else {
            resourceIndexPath = forward ? navigatorCentral.nextAssetAfter( resourceIndexPath ) : navigatorCentral.previousAssetBefore( resourceIndexPath )
            logVerbose( "stayInFolder[ false ]  forward[ %@ ] -> resourceIndexPath[ %@ ]", stringFor( forward ), stringFor( resourceIndexPath ) )
        }
        
        deviceAsset = navigatorCentral.deviceAssetAt( resourceIndexPath )
        
        requestAssetData()
    }
    
}



// MARK: Image Slide Show Timer Methods (NOT used for videos)

extension MediaViewerViewController {
    
    private func disableImageSlideShowTimer() {
        logTrace()
        if let timer = slideShowTimer {
            if timer.isValid {
                timer.invalidate()
            }
            
        }

        slideShowTimer = nil
    }


    func startImageSlideShowTimer() {
        logTrace()
        
        DispatchQueue.main.async {
            self.slideShowTimer = Timer.scheduledTimer( withTimeInterval: Double( self.navigatorCentral.imageDuration ), repeats: false ) { (timer) in
                logVerbose( "Timer Expired" )
               
                if self.presentingAssets {
                    self.requestNextAsset( forward: true )
                }
                else {
                    self.requestNextMediaFile( forward: true )
                }
                
                self.delegate.mediaViewerViewController( self, didShowMediaAt: self.resourceIndexPath )
            }
                
        }
        
    }


}

    
    
    // MARK: MediaFile Methods
    
extension MediaViewerViewController {
            
    private func requestMediaFileData() {
        logTrace()
        let filePath            = mediaFile.relativePath ?? ""
        let fullPathAndFilename = ( filePath.isEmpty ? "" : filePath + "/" ) + mediaFile.filename!
        
        mediaNameLabel.text = navigatorCentral.sectionTitleArray[ resourceIndexPath.section ] + "/" + mediaFile.filename!
        
        disableImageSlideShowTimer()
        
        myActivityIndicator.isHidden = false
        myActivityIndicator.startAnimating()

        if nasSessionActive {
            nasCentral.fetchFileOn( connectedShare, fullPathAndFilename, self )
        }
        else {
            nasCentral.canSeeNasDataSourceFolders( self )
        }
        
    }
    
    
    
    // MARK: MediaFile Utility Methods
    
    private func cacheVideoFromMediaFile() -> Bool {
        guard let _ = documentDirctoryUrl else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return false
        }
        
        currentVideoUrl = picturesDirectoryUrl.appendingPathComponent( mediaFile.filename! )
        let videoCached = fileManager.createFile( atPath: currentVideoUrl.path, contents: fileData, attributes: nil )
        
        logVerbose( "videoCached[ %@ ] bytes[  %d ] for [ %@ ]", stringFor( videoCached ), fileData.count, mediaFile.filename! )
        
        return videoCached
    }
    
    
    private func emptyVideoCache() -> Bool {
        guard let _ = documentDirctoryUrl else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return false
        }
        
        var deletedFileCount = 0
        
        do {
            let urlArray = try fileManager.contentsOfDirectory(at: picturesDirectoryUrl, includingPropertiesForKeys: nil, options: [] )
            
            for url in urlArray {
                try fileManager.removeItem(at: url )
                
                logVerbose( "deleted [ %@ ]",  url.lastPathComponent )
                deletedFileCount += 1
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "ERROR!!!  [ %@ ]\n    [ %@ ]", error.localizedDescription, picturesDirectoryUrl.path )
            return false
        }

        logVerbose( "deleted [ %d ] files", deletedFileCount )
        
        return true
    }
    
    
    private func loadVideoFromMediaFile() {
        if !cacheVideoFromMediaFile() {
            logTrace( "ERROR!  unable to cache video file... skipping to next file" )
            requestNextMediaFile( forward: true )
            return
        }

        logTrace()
        loadPlayerWithVideoFromMediaFile()
        playVideo()
    }
    
    
    private func loadPlayerWithVideoFromMediaFile() {
        logTrace()
        let player      = AVPlayer(url: URL( fileURLWithPath: currentVideoUrl.path ) )
        let playerLayer = AVPlayerLayer( player: player )
        
        // Since myImageView has constraints on it that will automatically reposition and resize itself,
        // we attach the playerLayer to it so it can just tag along for the ride
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        playerLayer.frame        = myImageView.layer.bounds
        
        myImageView.layer.addSublayer( playerLayer )
        myImageView.isHidden = false

        self.playerLayer = playerLayer
    }
    
    
    private func requestNextMediaFile( forward: Bool ) {
        if navigatorCentral.stayInFolder {
            logVerbose( "stayInFolder[ true ]  shuffleImages[ %@ ]", stringFor( navigatorCentral.shuffleImages ) )
            
            if navigatorCentral.shuffleImages {
                resourceIndexPath = navigatorCentral.nextShuffledMediaFile( resourceIndexPath )
            }
            else {
                let currentSection = resourceIndexPath.section
                
                resourceIndexPath = navigatorCentral.nextMediaFileAfter( resourceIndexPath )
                
                if resourceIndexPath.section != currentSection {
                    resourceIndexPath.section = currentSection
                    resourceIndexPath.item    = 0
                }
                
            }
            
        }
        else {
            logVerbose( "stayInFolder[ false ]  forward[ %@ ]", stringFor( forward ) )
            resourceIndexPath = forward ? navigatorCentral.nextMediaFileAfter( resourceIndexPath ) : navigatorCentral.previousMediaFileBefore( resourceIndexPath )
        }
        
        mediaFile = navigatorCentral.mediaFileAt( resourceIndexPath )
        
        requestMediaFileData()
    }
    
}



// MARK: NASCentralDelegate Methods

extension MediaViewerViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        
        if canSeeNasDataSourceFolders {
            if !nasSessionActive {
                nasCentral.startDataSourceSession( self )
            }
            else {
                var filePathAndName = ""
                
                if let relativePath = mediaFile.relativePath,
                   let filename     = mediaFile.filename {
                    filePathAndName = relativePath + "/" + filename
                }
                
                logVerbose( "requesting data from [ %@ ]", filePathAndName )
                nasCentral.fetchFileOn( connectedShare, filePathAndName, self )
            }

        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFile: Bool, _ data: Data ) {
        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        
        nasSessionActive = didFetchFile

        if didFetchFile {
            fileData = data
            presentMediaFileDocument()
        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.UnableToFetchFileFromNAS", comment: "Unable to fetch file from NAS!" ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didOpenShare: Bool, _ share: SMBShare) {
        logVerbose( "[ %@ ]", stringFor( didOpenShare ) )
        if didOpenShare {
            var filePathAndName = ""
            
            if let relativePath = mediaFile.relativePath,
               let filename     = mediaFile.filename {
                filePathAndName = relativePath + "/" + filename
            }
            
            logVerbose( "requesting data from [ %@ ]", filePathAndName )
            nasCentral.fetchFileOn( connectedShare, filePathAndName, self )
        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.UnableToFetchFileFromNAS", comment: "Unable to fetch file from NAS!" ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession: Bool, share: SMBShare ) {
        logVerbose( "[ %@ ]", stringFor( didStartDataSourceSession ) )
        
        if didStartDataSourceSession {
            connectedShare = share
            nasCentral.openShare( share, self )
        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.UnableToStartSession", comment: "Unable to start a session with the selected share!" ) )
        }
        
    }
    
    
    
    // MARK: NASCentralDelegate Utility Methods
    
    private func presentMediaFileDocument() {
        logTrace()
        resetViews()
        loadingData = false
        
        myActivityIndicator.isHidden = true
        myActivityIndicator.stopAnimating()
        
        myImageView.isHidden = true
        myWebView  .isHidden = true
        
        let fileExtension = extensionFrom( mediaFile.filename! ).uppercased()
        
        if GlobalConstants.videoFilenameExtensions.contains( fileExtension ) {
            loadVideoFromMediaFile()
        }
        else if GlobalConstants.imageFilenameExtensions.contains( fileExtension ) {
            let myImage = UIImage(data: fileData )
            
            myImageView.isHidden = false
            myImageView.image    = myImage
            
            if slideShowActive {
                startImageSlideShowTimer()
            }
            
        }
        else if GlobalConstants.webFilenameExtensions.contains( fileExtension ) {
            let mimeType = navigatorCentral.mimeTypeFor( mediaFile )
            
            myWebView.isHidden = false
            myWebView.load( fileData, mimeType: mimeType, characterEncodingName: "UTF8", baseURL: URL(string: "http://localhost")! )
            
            if slideShowActive {
                startImageSlideShowTimer()
            }
            
        }
        else {
            // TODO: Watch for this!
            logVerbose( "ERROR!!!  Skipping unexpected media type[ %@ ]", fileExtension )
            requestNextMediaFile( forward: true )
        }
        
    }
    
    
}



// MARK: WKNavigationDelegate Methods

extension MediaViewerViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        return .allow
    }


    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        return WKNavigationResponsePolicy.cancel
    }


    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logVerbose( "error[ %@ ]", error.localizedDescription )
    }


    private func nameFor(_ navigationAction: WKNavigationAction ) -> String {
        var name = "???"
        
        switch navigationAction.navigationType {
        case .linkActivated:     name = "link activation"
        case .formSubmitted:     name = "request to submit a form"
        case .backForward:       name = "request for the frame’s next or previous item"
        case .reload:            name = "request to reload the webpage"
        case .formResubmitted:   name = "request to resubmit a form"
        case .other:             name = "other"
        default:                 break
        }
        
        return name
    }


}

