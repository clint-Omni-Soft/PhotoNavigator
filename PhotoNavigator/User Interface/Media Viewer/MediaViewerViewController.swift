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
    
    @IBOutlet weak var mediaNameLabel     : UILabel!
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myImageView        : UIImageView!
    @IBOutlet weak var myWebView          : WKWebView!
    
    
    // MARK: Public Interfaces
    
    func displayAssetAt(_ indexPath: IndexPath, _ delegate: MediaViewerViewControllerDelegate ) {
        self.delegate     = delegate
        deviceAsset       = navigatorCentral.deviceAssetAt( indexPath )
        presentingAssets  = true
        resourceIndexPath = indexPath
        slideShowActive   = startImageSlideShow
        
        logVerbose( "[ %@ ][ %@ ]  resigningActive[ %@ ]", stringFor( indexPath ), deviceAsset.descriptorString(), stringFor( navigatorCentral.resigningActive ) )
        
        if !navigatorCentral.resigningActive {
            requestAssetData()
            loadBarButtonItems()
        }
        else {
            requestPending = true
        }
        
    }
    
    
    func displayMediaFileAt(_ indexPath: IndexPath, _ delegate: MediaViewerViewControllerDelegate ) {
        self.delegate     = delegate
        mediaFile         = navigatorCentral.mediaFileAt( indexPath )
        presentingAssets  = false
        resourceIndexPath = indexPath
        slideShowActive   = startImageSlideShow

        logVerbose( "[ %@ ][ %@ ]  resigningActive[ %@ ]", stringFor( indexPath ), mediaFile.filename!, stringFor( navigatorCentral.resigningActive ) )
        
        if !navigatorCentral.resigningActive {
            requestMediaFileData()
            loadBarButtonItems()
        }
        else {
            requestPending = true
        }
        
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
    private let cachingImageManager     = PHCachingImageManager()
    private var connectedShare          : SMBShare!
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
    private var primaryWindowIsHidden   = false
    private var playerLayer             : AVPlayerLayer!
    private var presentingAssets        = false
    private var requestPending          = false
    private var resourceIndexPath       = GlobalIndexPaths.noSelection
    private var nasSessionActive        = false
    private var slideShowActive         = false
    private var slideShowTimer          : Timer!
    private var startImageSlideShow     = false
    private var videoFileUrl            : URL!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
//        navigationItem.title = NSLocalizedString( "Title.MediaViewer",   comment: "Media Viewer" )
        navigationItem.title = ""
        
        appDelegate.mediaViewer = self
        documentDirctoryUrl     = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last
        myActivityIndicator.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        registerForNotifications()
        
        mediaNameLabel.text = ""
        myImageView.isHidden = true
        
        myWebView.allowsBackForwardNavigationGestures = false
        myWebView.contentMode        = .scaleAspectFit
        myWebView.isHidden           = true
        myWebView.navigationDelegate = self
        
        loadBarButtonItems()
        
        if startImageSlideShow {
            startImageSlideShowTimer()
        }
        else {
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
        
        disableImageSlideShowTimer()
        notificationCenter.removeObserver( self )
    }
    
    
    override func viewWillTransition( to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator ) {
        super.viewWillTransition( to: size, with: coordinator )
        
        if !navigatorCentral.resigningActive {
            logVerbose( "[ %@ ]", stringFor( size ) )
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
        
    }
    
    
    
    // MARK: Notification Methods
    
    @objc func enteringForeground( notification: NSNotification ) {
        logTrace()
        if startImageSlideShow {
            startImageSlideShowTimer()
        }
        
    }
    
    
    @objc func playerDidFinishPlayingVideo( notification: NSNotification ) {
        logTrace()
        cleanUpPlayer()

        if presentingAssets {
            requestNextAsset( forward: true )
        }
        else {
            requestNextMediaFile( forward: true )
        }
        
        delegate.mediaViewerViewController( self, didShowMediaAt: self.resourceIndexPath )
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func fastForwardBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        cleanUpPlayer()
        disableImageSlideShowTimer()
        loadBarButtonItems()
        
        if presentingAssets {
            requestNextAsset( forward: true )
        }
        else {
            requestNextMediaFile( forward: true )
        }
        
        delegate.mediaViewerViewController( self, didShowMediaAt: self.resourceIndexPath )
    }
    
    
    @IBAction func pauseOrPlayBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        slideShowActive = !slideShowActive
        
        if slideShowActive {
            appDelegate.hidePrimaryView( true )
            
            if playerLayer == nil {
                startImageSlideShowTimer()
            }
            else {
                playerLayer.player?.play()
            }
            
        }
        else {
            disableImageSlideShowTimer()
            nasSessionActive = false
            
            if playerLayer != nil {
                playerLayer.player?.pause()
           }
            
        }
        
        loadBarButtonItems()
    }
    
    
    @IBAction func rewindBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        cleanUpPlayer()
        disableImageSlideShowTimer()
        loadBarButtonItems()
        
        if presentingAssets {
            requestNextAsset( forward: false )
        }
        else {
            requestNextMediaFile( forward: false )
        }
        
        delegate.mediaViewerViewController( self, didShowMediaAt: self.resourceIndexPath )
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
    
    
    
    // MARK: Utility Methods
    
    private func cleanUpPlayer() {
        logTrace()
        if let _ = playerLayer {
            playerLayer.removeFromSuperlayer()
            playerLayer = nil
            
            if !presentingAssets && !emptyVideoCache() {
                logTrace( "ERROR!!!  Need cleanup on aisle #9!" )
            }
            
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        var leftBarButtonItems : [UIBarButtonItem] = []
        let pauseOrPlayButton  : UIBarButtonItem.SystemItem = slideShowActive ? .pause : .play
        var rightBarButtonItems: [UIBarButtonItem] = []
        
        if resourceIndexPath != GlobalIndexPaths.noSelection {
            rightBarButtonItems.append( UIBarButtonItem.init(barButtonSystemItem: .fastForward,      target: self, action: #selector( fastForwardBarButtonItemTouched(_:) ) ) )
            rightBarButtonItems.append( UIBarButtonItem.init(barButtonSystemItem: pauseOrPlayButton, target: self, action: #selector( pauseOrPlayBarButtonItemTouched(_:) ) ) )
            rightBarButtonItems.append( UIBarButtonItem.init(barButtonSystemItem: .rewind,           target: self, action: #selector( rewindBarButtonItemTouched(_     :) ) ) )
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad && primaryWindowIsHidden {
            leftBarButtonItems.append( UIBarButtonItem.init(image: UIImage(named: "hamburger" ), style: .plain, target: self, action: #selector( showPrimaryBarButtonItemTouched(_:) ) ) )
        }
        
        navigationItem.leftBarButtonItems  = leftBarButtonItems
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    
    private func registerForNotifications() {
        logTrace()
        NotificationCenter.default.addObserver( self, selector: #selector( self.enteringForeground( notification: ) ), name: NSNotification.Name( rawValue: Notifications.enteringForeground ), object: nil )
    }
    
    
    private func resetViews() {
        logTrace()
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        
        myImageView.image    = nil
        myImageView.isHidden = true
        myWebView  .isHidden = true
        
//        myActivityIndicator.startAnimating()
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
                    logTrace( "image loaded" )
//                    self.myActivityIndicator.stopAnimating()
                    
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
//            myActivityIndicator.stopAnimating()
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
            
            logTrace( "video loaded" )
            
            if self.slideShowActive {
                player.play()
                
                self.notificationCenter.addObserver( self, selector: #selector( self.playerDidFinishPlayingVideo( notification: ) ),
                                                     name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem )
            }
            
//            self.myActivityIndicator.stopAnimating()
        })
        
    }
    
    
    private func requestNextAsset( forward: Bool ) {
        logVerbose( "forward[ %@ ]", stringFor( forward ) )
        resourceIndexPath = forward ? navigatorCentral.nextAssetAfter( resourceIndexPath ) : navigatorCentral.previousAssetBefore( resourceIndexPath )
        deviceAsset       = navigatorCentral.deviceAssetAt( resourceIndexPath )
        
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
                startImageSlideShow = true
            }
            
        }

        slideShowTimer = nil
    }


    func startImageSlideShowTimer() {
        logVerbose( "resigningActive[ %@ ]", stringFor( navigatorCentral.resigningActive ) )
        
        if !navigatorCentral.resigningActive {
            DispatchQueue.main.async {
                self.slideShowTimer = Timer.scheduledTimer( withTimeInterval: Double( self.navigatorCentral.imageDuration ), repeats: false ) { (timer) in
                    logVerbose( "Timer Expired  resigningActive[ %@ ]", stringFor( self.navigatorCentral.resigningActive ) )
                   
                    self.startImageSlideShow = self.navigatorCentral.resigningActive
                    
                    if !self.navigatorCentral.resigningActive {
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
        
    }


}

    
    
    // MARK: MediaFile Methods
    
extension MediaViewerViewController {
            
    private func requestMediaFileData() {
        logTrace()
        let filePath            = mediaFile.relativePath ?? ""
        let fullPathAndFilename = ( filePath.isEmpty ? "" : filePath + "/" ) + mediaFile.filename!
        
        mediaNameLabel.text = fullPathAndFilename
        disableImageSlideShowTimer()

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
        
        videoFileUrl = documentDirctoryUrl.appendingPathComponent( DirectoryNames.pictures )
        videoFileUrl = videoFileUrl       .appendingPathComponent( mediaFile.filename!     )
        
        let videoCached = fileManager.createFile( atPath: videoFileUrl.path, contents: fileData, attributes: nil )
        
        if videoCached {
            logTrace()
        }
        else {
            logVerbose( "ERROR!!!  Unable to create cache file for\n    [ %@ ]", videoFileUrl.path )
        }
        
        return videoCached
    }
    
    
    private func emptyVideoCache() -> Bool {
        guard let _ = documentDirctoryUrl else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return false
        }
        
        videoFileUrl = documentDirctoryUrl.appendingPathComponent( DirectoryNames.pictures )
        
        do {
            let urlArray = try fileManager.contentsOfDirectory(at: videoFileUrl, includingPropertiesForKeys: nil, options: [] )
            
            for url in urlArray {
                try fileManager.removeItem(at: url )
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "ERROR!!!  [ %@ ]\n    [ %@ ]", error.localizedDescription, videoFileUrl.path )
            return false
        }

        logTrace()
        
        return true
    }
    
    
    private func loadVideoFromMediaFile() {
        logTrace()
        if !cacheVideoFromMediaFile() {
            requestNextMediaFile( forward: true )
            return
        }

        loadPlayerWithVideoFromMediaFile()

        if slideShowActive {
            playerLayer.player!.play()

            notificationCenter.addObserver( self, selector: #selector( self.playerDidFinishPlayingVideo( notification: ) ),
                                            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerLayer.player!.currentItem )
        }
        
//        myActivityIndicator.stopAnimating()
    }
    
    
    private func loadPlayerWithVideoFromMediaFile() {
        logTrace()
        let player      = AVPlayer(url: URL( fileURLWithPath: videoFileUrl.path ) )
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
        logTrace()
        resourceIndexPath = forward ? navigatorCentral.nextMediaFileAfter( resourceIndexPath ) : navigatorCentral.previousMediaFileBefore( resourceIndexPath )
        mediaFile         = navigatorCentral.mediaFileAt( resourceIndexPath )
        
        requestMediaFileData()
    }
    
}



// MARK: NASCentralDelegate Methods

extension MediaViewerViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        if canSeeNasDataSourceFolders {
            nasCentral.startDataSourceSession( self )
        }
        else {
//            myActivityIndicator.stopAnimating()
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFile: Bool, _ data: Data ) {
        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        
        if didFetchFile {
            fileData = data
            nasSessionActive = slideShowActive
            presentMediaFileDocument()
        }
        else {
//            myActivityIndicator.stopAnimating()
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
            
            nasCentral.fetchFileOn( connectedShare, filePathAndName, self )
        }
        else {
//            myActivityIndicator.stopAnimating()
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
//            myActivityIndicator.stopAnimating()
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.UnableToStartSession", comment: "Unable to start a session with the selected share!" ) )
        }
        
    }
    
    
    
    // MARK: NASCentralDelegate Utility Methods
    
    private func presentMediaFileDocument() {
        logTrace()
        resetViews()
        loadingData = false
        
//        myActivityIndicator.stopAnimating()
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

