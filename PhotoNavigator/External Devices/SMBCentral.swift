//
//  SMBCentral.swift
//  WineStock
//
//  Created by Clint Shank on 2/29/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import Foundation


protocol SMBCentralDelegate : AnyObject {
    
    // Access Methods
    func smbCentral(_ smbCentral : SMBCentral, didConnectToDevice  : Bool )
    func smbCentral(_ smbCentral : SMBCentral, didCreateDirectory  : Bool )
    func smbCentral(_ smbCentral : SMBCentral, didFetchDirectories : Bool, _ directoryArray : [SMBFile] )
    func smbCentral(_ smbCentral : SMBCentral, didFetchShares      : Bool, _ shares : [SMBShare] )

    // Session Methods
    func smbCentral(_ smbCentral : SMBCentral, didDeleteFile   : Bool, _ filename  : String )
    func smbCentral(_ smbCentral : SMBCentral, didEndSession   : Bool )
    func smbCentral(_ smbCentral : SMBCentral, didFetchFiles   : Bool, _ fileArray : [SMBFile] )
    func smbCentral(_ smbCentral : SMBCentral, didReadFile     : Bool, _ fileData  : Data )
    func smbCentral(_ smbCentral : SMBCentral, didStartSession : Bool )
    func smbCentral(_ smbCentral : SMBCentral, didWriteFile    : Bool )

    // Self-Contained Methods
    func smbCentral(_ smbCentral : SMBCentral, didFetchFile  : Bool, _ fileData : Data )
    func smbCentral(_ smbCentral : SMBCentral, didFindFolder : Bool )
    func smbCentral(_ smbCentral : SMBCentral, didSaveData   : Bool )
}


// Now we supply we provide a default implementation which makes them all optional
extension SMBCentralDelegate {
    
    // Access Methods
    func smbCentral(_ smbCentral : SMBCentral, didConnectToDevice  : Bool ) {}
    func smbCentral(_ smbCentral : SMBCentral, didCreateDirectory  : Bool ) {}
    func smbCentral(_ smbCentral : SMBCentral, didFetchDirectories : Bool, _ directoryArray : [SMBFile] ) {}
    func smbCentral(_ smbCentral : SMBCentral, didFetchShares      : Bool, _ shares : [SMBShare] ) {}
    
    // Session Methods
    func smbCentral(_ smbCentral : SMBCentral, didDeleteFile   : Bool, _ filename  : String  ) {}
    func smbCentral(_ smbCentral : SMBCentral, didEndSession   : Bool ) {}
    func smbCentral(_ smbCentral : SMBCentral, didFetchFiles   : Bool, _ fileArray : [SMBFile] ) {}
    func smbCentral(_ smbCentral : SMBCentral, didReadFile     : Bool, _ fileData  : Data ) {}
    func smbCentral(_ smbCentral : SMBCentral, didStartSession : Bool ) {}
    func smbCentral(_ smbCentral : SMBCentral, didWriteFile    : Bool ) {}

    // Self-Contained Methods
    func smbCentral(_ smbCentral : SMBCentral, didFetchFile  : Bool, _ fileData : Data ) {}
    func smbCentral(_ smbCentral : SMBCentral, didFindFolder : Bool ) {}
    func smbCentral(_ smbCentral : SMBCentral, didSaveData   : Bool ) {}
}



struct NASDescriptor {
    var host        = ""
    var netbiosName = ""
    var group       = ""
    var userName    = ""
    var password    = ""
    var share       = ""
    var path        = ""
}



class SMBCentral: NSObject {
    
    // MARK: Public Variables
    
    var connectedShare: SMBShare!
    var connectedToDevice           = false
    var deviceArray   : [SMBDevice] = []
    var sharesArray   : [SMBShare]  = []
    var returnCsvFiles              = false
    var shareOpen                   = false

    
    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = SMBCentral()        // Prevents anyone else from creating an instance
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let timerDuration = Double( 60 )
    }
    
    private var connectedDevice     : SMBDevice?
    private var connectedFileServer : SMBFileServer!
    private var deviceSet           = Set<SMBDevice>()
    private var fileToBeDeleted     = ""
    private var startSessionTimer   : Timer!

}



extension SMBCentral {
    
    // MARK: Discovery Methods (non-protocol based)

    func startDiscoveryWith(_ delegate : SMBCentralDelegate ) -> Bool {
        deviceArray.removeAll()
        deviceSet  .removeAll()

        let     discoveryStarted = SMBDiscovery.sharedInstance()!.start( of: .any, added: {
            (device) in
            
            var     isDuplicate = false
            
            for setDevice in self.deviceSet {
                if device.netbiosName == setDevice.netbiosName {
                    isDuplicate = true
                    break
                }
                
            }
            
            if !isDuplicate {
                self.deviceSet.insert( device )
                logVerbose( "Added[ %@ ]", device.netbiosName )
            }

        }) {
            (device) in
            
            logVerbose( "Removed[ %@ ]", device.netbiosName )
            self.deviceSet.remove( device )
        }
        
        logVerbose( "discoveryStarted[ %@ ]", stringFor( discoveryStarted ) )
        
        return discoveryStarted
    }
    
    
    func stopDiscovery() {
        logVerbose( "Found [ %d ] devices", deviceSet.count )
        SMBDiscovery.sharedInstance()!.stop()
        
        deviceArray = Array( deviceSet )
        
        deviceArray = deviceArray.sorted(by: {
            (device1, device2) -> Bool in
            
            device1.netbiosName.uppercased() < device2.netbiosName.uppercased()
        })
        
    }
    
    
    
    // MARK: Access Methods
    
    func close(_ share : SMBShare ) {
        if share.isOpen {
            share.close( nil )
//            logVerbose( "share[ %@ ]", share.name )
        }
        
        shareOpen = false
    }
        
        
    func connectTo(_ device : SMBDevice, _ userName : String, _ password : String, _ delegate : SMBCentralDelegate ) {
        connectedToDevice = false
        
        if let fileServer = SMBFileServer.init( host: device.host, netbiosName: device.netbiosName, group: device.group ) {
            self.connectedFileServer = fileServer

            fileServer.connect( asUser: userName, password: password, completion: {
                (guestFlag, error) in
                
                self.connectedDevice = device
                
                if !guestFlag && ( error == nil ) {
                    self.connectedToDevice = true
//                    logVerbose( "[ %@ ]", device.netbiosName )
                }
                else {
                    logVerbose( "\n    ERROR!  logIn failed! ... guestFlag[ %@ ]  error[ %@ ]", stringFor( guestFlag ), error?.localizedDescription ?? "None" )
                    self.disconnect()
                }
                
                delegate.smbCentral( self, didConnectToDevice: self.connectedToDevice )
            } )
            
        }
        else {
            logTrace( "ERROR!  Unable to instantiate server using this device!" )
            delegate.smbCentral( self, didConnectToDevice: connectedToDevice )
        }

    }
    
    
    func disconnect() {
        if connectedFileServer != nil && connectedDevice != nil {
            connectedFileServer.disconnect( nil )
//            logVerbose( "from device [ %@ ]", connectedDevice?.netbiosName ?? "Unknown" )
        }
     
        connectedDevice     = nil
        connectedToDevice   = false
        connectedFileServer = nil
    }
    
    
    func createDirectoryOn(_ share : SMBShare, _ path : String, _ delegate : SMBCentralDelegate ) {
        let     smbFile = SMBFile.init( path: path, share: share )
        
        smbFile?.createDirectory( {
            (error) in
            
            let didCreate = ( error == nil )
            
            if didCreate {
//                logVerbose( "Created directory at [ %@ ]", path )
            }
            else {
                logVerbose( "ERROR!  [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown error" )
            }
            
            delegate.smbCentral( self, didCreateDirectory : didCreate )
        })
        
    }
    
    
    func fetchDirectoriesFor(_ share : SMBShare, _ startingPath : String, _ delegate : SMBCentralDelegate ) {
//        logVerbose( "[ %@/%@ ]", share.name, startingPath )
        var     csvFileArray   : [SMBFile] = []
        var     directoryArray : [SMBFile] = []
        let     root           = SMBFile.init( path: startingPath, share: share )

        root?.listFiles( filter: {
            (smbFile) -> Bool in
            
            if smbFile.isDirectory {
                if !smbFile.name.hasPrefix( "." ) {
                    directoryArray.append( smbFile )
                }
                
            }
            else if self.returnCsvFiles {
                if smbFile.name.hasSuffix( ".csv" ) || smbFile.name.hasSuffix( ".CSV" ) {
                    csvFileArray.append( smbFile )
                }
                
            }
            
            return smbFile.isDirectory
            
        }, completion: {
            ( files : [SMBFile]?, error ) in
            
            if let thisError = error {
                logVerbose( "ERROR!  Unable to list files[ %@ ]", thisError.localizedDescription )
                delegate.smbCentral( self, didFetchDirectories : false, [] )
            }
            else {
                if let _ = files {
                    
                    directoryArray = directoryArray.sorted(by: {
                        (file1, file2) -> Bool in
                        file1.name.uppercased() < file2.name.uppercased()
                    })
                    
                    if self.returnCsvFiles {
                        csvFileArray = csvFileArray.sorted(by: {
                            (file1, file2) -> Bool in
                            file1.name.uppercased() < file2.name.uppercased()
                        })
                     
                        directoryArray.append( contentsOf: csvFileArray )
                    }
                    
                }
                
                delegate.smbCentral( self, didFetchDirectories : true, directoryArray )
            }
            
        })
                    
    }


    func fetchSharesOnConnectedDevice(_ delegate : SMBCentralDelegate ) {
        sharesArray.removeAll()
        
        self.connectedFileServer.listShares({
            ( shares : [SMBShare]?, error )  in
            
            if error != nil {
                logVerbose( "ERROR!  [ %@ ]", error?.localizedDescription ?? "Unknown error" )
                delegate.smbCentral( self, didFetchShares: false, [] )
            }
            else {
                if let shareArray = shares {
                    self.sharesArray = shareArray
                    
                    self.sharesArray = self.sharesArray.sorted(by: {
                        (share1, share2) -> Bool in
                        share1.name.uppercased() < share2.name.uppercased()
                    })
                    
                }
                else {
                    logTrace( "ERROR!  Could not unwrap shareArray... returning empty array!" )
                }

                delegate.smbCentral( self, didFetchShares: true, self.sharesArray )
            }
            
        } )
            
    }

    
    func openAndFetchDirectoriesOn(_ share : SMBShare, _ delegate : SMBCentralDelegate ) {
        shareOpen = false
        
        share.open {
            (error) in
            
            if let myError = error {
                logVerbose( "ERROR!  Unable to open share[ %@ ] ... [ %@ ]", share.name, myError.localizedDescription )
                share.close( nil )
            }
            else {
//                logVerbose( "Opened share[ %@ ]", share.name )
                self.connectedShare = share
                self.shareOpen      = true
                
                self.fetchDirectoriesFor( share, "/", delegate )
            }
            
        }
        
    }
    

}



// MARK: Session Methods

extension SMBCentral {
    
    func deleteFileAt(_ path : String, _ delegate : SMBCentralDelegate ) {

        if !connectedToDevice || !shareOpen {
            logVerbose( "ERROR!  We NOT in the right state!  connectedToDevice[ %@ ] shareOpen[ %@ ]", stringFor( connectedToDevice ), stringFor( shareOpen )  )
            
            delegate.smbCentral( self, didDeleteFile: false, path )
            return
        }
        
        let     smbFile  = SMBFile.init( path: path, share: connectedShare! )
        
        smbFile?.updateStatus( {
            (error) in
            
            if error != nil {
                logVerbose( "ERROR!  Unable to get status on [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                delegate.smbCentral( self, didDeleteFile: false, path )
           }
            else {
                if let _ = smbFile?.exists {
                    
                    smbFile?.delete( {
                        (error) in
                        
                        if error != nil {
                            logVerbose( "ERROR!  [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                        }
                        
                        delegate.smbCentral( self, didDeleteFile: ( error == nil ), path )
                    } )
                    
                }
                else {
                    delegate.smbCentral( self, didDeleteFile: false, path )
                }
                
            }
            
        } )
        
    }
    
    
    func endSession(_ delegate : SMBCentralDelegate ) {
//        logVerbose( "shareOpen[ %@ ]  connectedToDevice[ %@ ]", stringFor( shareOpen ), stringFor( connectedToDevice ) )
        
        if shareOpen {
            
            connectedShare?.close( {
                (error) in
                
                if error != nil {
                    logVerbose( "ERROR!  [ %@ ]", error?.localizedDescription ?? "Unknown error" )
                }
                
                self.connectedShare = nil
                self.shareOpen      = false
                
                if self.connectedToDevice {
                    
                    self.connectedFileServer.disconnect({
                        self.connectedFileServer = nil
                        self.connectedToDevice   = false
                        
                        delegate.smbCentral( self, didEndSession: true )
                    })
                    
                }
                else {
                    logTrace( "ERROR!  We had a share open but the device was NOT!" )
                    delegate.smbCentral( self, didEndSession: true )
                }
                
            } )
            
        }
        else if connectedToDevice {
            
            self.connectedFileServer.disconnect({
                self.connectedFileServer = nil
                self.connectedToDevice   = false
                
                delegate.smbCentral( self, didEndSession: true )
            })
            
        }
        else {
            DispatchQueue.global().async {
                delegate.smbCentral( self, didEndSession: true )
            }
            
        }
        
    }
        
        
    func fetchFilesAt(_ startingPath : String, _ delegate : SMBCentralDelegate ) {
        logVerbose( "[ %@%@ ]", connectedShare!.name, startingPath )
        var     fileArray : [SMBFile] = []

        if !connectedToDevice || !shareOpen {
            logVerbose( "ERROR!  We NOT in the right state!  connectedToDevice[ %@ ] shareOpen[ %@ ]", stringFor( connectedToDevice ), stringFor( shareOpen )  )
            
            delegate.smbCentral( self, didFetchFiles: false, [] )
            return
        }
        
        let     root = SMBFile.init( path: startingPath, share: connectedShare! )

        root?.listFiles( filter: {
            (smbFile) -> Bool in
            
            if !smbFile.isDirectory && !smbFile.name.hasPrefix( "." ) {
                fileArray.append( smbFile )
            }
            
            return smbFile.isDirectory
            
        }, completion: {
            ( files : [SMBFile]?, error ) in
            
            if let thisError = error {
                logVerbose( "ERROR!  Unable to list files[ %@ ]", thisError.localizedDescription )
                delegate.smbCentral( self, didFetchFiles: false, [] )
            }
            else {
                if let _ = files {
                    
                    fileArray = fileArray.sorted(by: {
                        (file1, file2) -> Bool in
                        file1.name.uppercased() < file2.name.uppercased()
                    })
                    
                }
                
                delegate.smbCentral( self, didFetchFiles : true, fileArray )
            }
            
        })

    }


    func readFileAt(_ path : String, _ delegate : SMBCentralDelegate ) {
        var     fileData = Data.init()
        
        if !connectedToDevice || !shareOpen {
            logVerbose( "ERROR!  We NOT in the right state!  connectedToDevice[ %@ ] shareOpen[ %@ ]", stringFor( connectedToDevice ), stringFor( shareOpen )  )
            
            delegate.smbCentral( self, didReadFile: false, fileData )
            return
        }
        
        if let smbFile  = SMBFile.init( path: path, share: connectedShare! ) {

            smbFile.updateStatus( {
                (error) in
                
                if error != nil {
                    logVerbose( "ERROR!  Unable to get status on [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                    delegate.smbCentral( self, didReadFile: false, fileData )
                }
                else {
                    if !smbFile.exists {
                        logVerbose( "[ %@ ] does NOT exist!", path )
                        delegate.smbCentral( self, didReadFile: false, fileData )
                    }
                    else {
                        smbFile.open( .read, completion: {
                            (error) in
                            
                            if error != nil {
                                logVerbose( "ERROR!  open failed!  [ %@ ]  error[ %@ ]", path, error?.localizedDescription ?? "Unknown" )
                                delegate.smbCentral( self, didReadFile: false, Data.init() )
                            }
                            else {
                                smbFile.read( 64000, progress: {
                                    ( bytesReadTotal, data, complete, error) -> Bool in
                                    
                                    if error != nil {
                                        logVerbose( "ERROR!  open failed!  [ %@ ]  error[ %@ ]", path, error?.localizedDescription ?? "Unknown" )
                                        delegate.smbCentral( self, didReadFile: false, Data.init() )
                                        return false
                                    }
                                    
//                                    logVerbose( "Read [ %ld ] bytes ... total[ %llu ] bytes [ %0.2f %% ]", data?.count ?? 0, bytesReadTotal, ( bytesReadTotal / ( smbFile!.size * 100 ) ) )
                                    if let myData = data {
                                        fileData.append( myData )
                                    }
                                    
                                    if complete {
//                                    logVerbose( "Read [ %ld ] bytes from [ %@ ]", bytesReadTotal, path )
                                        
                                        smbFile.close( {
                                            (error) in
                                            
                                            if error != nil {
                                                logVerbose( "ERROR!  close failed!  [ %@ ]  error[ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                                                delegate.smbCentral( self, didReadFile: false, Data.init() )
                                                return
                                            }
                                            
                                            delegate.smbCentral( self, didReadFile: true, fileData )
                                        })
                                        
                                    }
                                    
                                    return true
                                })
                                
                            }
                            
                        })
                        
                    }
                    
                }
                
            } )

        }
        
    }
        
        
    func startSession(_ nasDescriptor : NASDescriptor, _ delegate : SMBCentralDelegate ) {
        connectedToDevice = false
        shareOpen         = true
        
//        logTrace()
        if let myFileServer = SMBFileServer.init( host: nasDescriptor.host, netbiosName: nasDescriptor.netbiosName, group: nasDescriptor.group ) {
            if let timer = startSessionTimer {
                timer.invalidate()
            }

            DispatchQueue.main.async {
                self.startSessionTimer = Timer.scheduledTimer( withTimeInterval: Constants.timerDuration, repeats: false ) {
                    (timer) in
                    logTrace( "Network Error!" )
                    timer.invalidate()
                    
                    delegate.smbCentral( self, didStartSession: false )
                }
                
            }

            myFileServer.connect( asUser: nasDescriptor.userName, password: nasDescriptor.password, completion: {
                (guestFlag, error) in
                
                if let timer = self.startSessionTimer {
                    timer.invalidate()
                }

                logVerbose( "connected to fileServer ... search for share[ %@ ]", nasDescriptor.share )
                if !guestFlag && ( error == nil ) {
                    
                    myFileServer.findShare( nasDescriptor.share, completion: {
                        (share, error) in
                        
                        if error != nil {
                            logVerbose( "ERROR!  Unable to find share[ %@ ] ... [ %@ ]", nasDescriptor.share, error?.localizedDescription ?? "Unknown Error" )
                            myFileServer.disconnect( nil )
                            
                            delegate.smbCentral( self, didStartSession: false )
                        }
                        else {
                            share?.open( {
                                (error) in
                                
                                if error != nil {
                                    logVerbose( "ERROR!  Unable to open share[ %@ ] ... [ %@ ]", nasDescriptor.share, error?.localizedDescription ?? "Unknown Error" )
                                    myFileServer.disconnect( nil )
                                    
                                    delegate.smbCentral( self, didStartSession: false )
                                }
                                else {
                                    logTrace( "found share" )
                                    self.connectedFileServer = myFileServer
                                    self.connectedShare      = share
                                    self.connectedToDevice   = true
                                    self.shareOpen           = true
                                    
                                    delegate.smbCentral( self, didStartSession: true )
                                }
                                
                            })
                            
                        }
                        
                    })
                    
                }
                else {
                    logVerbose( "\n    ERROR!  logIn failed! ... guestFlag[ %@ ]  error[ %@ ]", stringFor( guestFlag ), error?.localizedDescription ?? "None" )
                    myFileServer.disconnect( nil )
                    
                    delegate.smbCentral( self, didStartSession: false )
                }
                
            } )
            
        }
        else {
            logVerbose( "ERROR!  Unable to instantiate server for [ %@ ]!", nasDescriptor.netbiosName )
            
            delegate.smbCentral( self, didStartSession: false )
        }
        
    }
    
    
    func writeData(_ data : Data, toFileAt path : String, _ delegate : SMBCentralDelegate ) {
        
        if !connectedToDevice || !shareOpen {
            logVerbose( "ERROR!  We NOT in the right state!  connectedToDevice[ %@ ] shareOpen[ %@ ]", stringFor( connectedToDevice ), stringFor( shareOpen )  )
            
            delegate.smbCentral( self, didReadFile: false, Data.init() )
            return
        }
        
//        logVerbose( "Opening [ %@ ]", path )
        let     smbFile         = SMBFile.init( path: path, share: connectedShare! )
        var     writeSuccessful = true
        
        smbFile?.open( .readWrite, completion: {
            (error) in
            
            if error != nil {
                logVerbose( "ERROR!  open failed!  [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                writeSuccessful = false
            }
            else {
                smbFile?.write( {
                    ( offset ) -> Data? in
                    
                    if offset < data.count {
                        let     blockSize = min( 64000, ( data.count - Int( offset ) ) )
                        let     range     = Range.init( uncheckedBounds: ( lower: Int( offset ), upper: Int( offset ) + blockSize ) )
                        
                        return data.subdata( in: range )
                    }
                    else {
                        return nil
                    }
                    
                }, progress: {
                    ( bytesWrittenTotal, bytesWrittenLast, complete, error ) in
                    
                    if error != nil {
                        logVerbose( "ERROR!  [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                        writeSuccessful = false
                    }
//                    else {
//                        let     progress = 100.0 * ( Float( bytesWrittenTotal ) / Float( data.count ) )
//
//                        logVerbose( "Bytes written[ %ld ] ... total written[ %llu ][ %3.0f%% ]", bytesWrittenLast, bytesWrittenTotal, progress )
//                    }
                    
                    if complete {
//                        logVerbose( "[ %@! ] [ %@ ]", ( writeSuccessful ? "Successful" : "Failed"), path )
                        
                        smbFile?.close( {
                            (error) in
                            
                            if error != nil {
                                logVerbose( "ERROR!  close failed!  [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                                writeSuccessful = false
                            }
                            
                            delegate.smbCentral( self, didWriteFile: writeSuccessful )
                        })
                        
                    }
                    
                })
                
            }
            
        } )
        
    }
    
    
}



// MARK: Self-Contained Methods

extension SMBCentral {
    
    func fetchFileOn(_ share : SMBShare, _ path : String, _ delegate : SMBCentralDelegate ) {
        var     fileData = Data.init()
        
        if let smbFile  = SMBFile.init( path: path, share: share ) {

            smbFile.updateStatus( {
                (error) in
                
                if error != nil {
                    logVerbose( "ERROR!  Unable to get status on [ %@ ][ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                    delegate.smbCentral( self, didFetchFile: false, fileData )
                }
                else {
                    if !smbFile.exists {
                        logVerbose( "[ %@ ] does NOT exist!", path )
                        delegate.smbCentral( self, didFetchFile: false, fileData )
                    }
                    else {
                        smbFile.open( .read, completion: {
                            (error) in
                            
                            if error != nil {
                                logVerbose( "ERROR!  open failed!  [ %@ ]  error[ %@ ]", path, error?.localizedDescription ?? "Unknown" )
                                delegate.smbCentral( self, didFetchFile: false, Data.init() )
                            }
                            else {
                                smbFile.read( 64000, progress: {
                                    ( bytesReadTotal, data, complete, error) -> Bool in
                                    
                                    if error != nil {
                                        logVerbose( "ERROR!  open failed!  [ %@ ]  error[ %@ ]", path, error?.localizedDescription ?? "Unknown" )
                                        delegate.smbCentral( self, didFetchFile: false, Data.init() )
                                        return false
                                    }
                                    
//                                    logVerbose( "Read [ %ld ] bytes ... total[ %llu ] bytes [ %0.2f %% ]", data?.count ?? 0, bytesReadTotal, ( bytesReadTotal / ( smbFile!.size * 100 ) ) )
                                    if let myData = data {
                                        fileData.append( myData )
                                    }
                                    
                                    if complete {
//                                    logVerbose( "Read [ %ld ] bytes from [ %@ ]", bytesReadTotal, path )
                                        
                                        smbFile.close( {
                                            (error) in
                                            
                                            if error != nil {
                                                logVerbose( "ERROR!  close failed!  [ %@ ]  error[ %@ ]", path, error?.localizedDescription ?? "Unknown Error" )
                                                delegate.smbCentral( self, didFetchFile: false, Data.init() )
                                                return
                                            }
                                            
                                            delegate.smbCentral( self, didFetchFile: true, fileData )
                                        })
                                        
                                    }
                                    
                                    return true
                                })
                                
                            }
                            
                        })
                        
                    }
                    
                }
                
            } )

        }

    }
        
                
    func findFolderAt(_ nasDescriptor : NASDescriptor, _ delegate : SMBCentralDelegate ) {
        
        if nasDescriptor.host.isEmpty {
            // We really don't know what to tell the user, so this is our way of saying 'maybe'
            delegate.smbCentral( self, didFindFolder: true )
            return
        }
        
        if let fileServer = SMBFileServer.init( host: nasDescriptor.host, netbiosName: nasDescriptor.netbiosName, group: nasDescriptor.group ) {
            
            fileServer.connect( asUser: nasDescriptor.userName, password: nasDescriptor.password, completion: {
                (guestFlag, error) in
                
                if !guestFlag && ( error == nil ) {
                    
                    fileServer.findShare( nasDescriptor.share, completion: {
                        (share, error) in
                        
                        if error != nil {
                            logVerbose( "ERROR!  Unable to find share[ %@ ] ... [ %@ ]", nasDescriptor.share, error?.localizedDescription ?? "Unknown Error" )
                            fileServer.disconnect( nil )
                            
                            delegate.smbCentral( self, didFindFolder: false )
                        }
                        else {
                            if let myShare = share {
                                
                                myShare.open( {
                                    (error) in
                                    
                                    if error != nil {
                                        logVerbose( "ERROR!  Unable to open share[ %@ ] ... [ %@ ]", nasDescriptor.share, error?.localizedDescription ?? "Unknown Error" )
                                        fileServer.disconnect( nil )
                                        
                                        delegate.smbCentral( self, didFindFolder: false )
                                    }
                                    else {
                                        var     folderExists = false
                                        
                                        if let smbFile = SMBFile.init( path : nasDescriptor.path, share : myShare ) {
                                            
                                            smbFile.updateStatus( {
                                                (error) in
                                                
                                                if error != nil {
                                                    logVerbose( "ERROR!  Unable to get status on WineStock folder .. [ %@ ]", error?.localizedDescription ?? "Unknown Error" )
                                                }
                                                else {
                                                    folderExists = smbFile.exists && smbFile.isDirectory
//                                                    logVerbose( "[ %@ ]", stringFor( folderExists ) )
                                                }
                                                
                                                myShare.close( {
                                                    (error) in
                                                    
                                                    fileServer.disconnect( nil )
                                                    
                                                    delegate.smbCentral( self, didFindFolder: folderExists )
                                                })
                                                
                                            })

                                        }
                                        
                                    }
                                    
                                })

                            }
                            
                        }
                        
                    })
                    
                }
                else {
                    logVerbose( "\n    ERROR!  logIn failed! ... guestFlag[ %@ ]  error[ %@ ]", stringFor( guestFlag ), error?.localizedDescription ?? "None" )
                    fileServer.disconnect( nil )
                    
                    delegate.smbCentral( self, didFindFolder: false )
                }
                
            } )
            
        }
        else {
            logVerbose( "ERROR!  Unable to instantiate server for [ %@ ]!", nasDescriptor.netbiosName )
            
            delegate.smbCentral( self, didFindFolder: false )
        }
        
    }
    
 
    func saveData(_ data : Data, _ share : SMBShare, _ fullPath : String, _ delegate : SMBCentralDelegate ) {
        let     smbFile         = SMBFile.init( path: fullPath, share: share )
        var     writeSuccessful = true
        
        smbFile?.open( .readWrite, completion: {
            (error) in
            
            if error != nil {
                logVerbose( "ERROR!  open failed!  [ %@ ][ %@ ]", fullPath, error?.localizedDescription ?? "Unknown Error" )
                writeSuccessful = false
            }
            else {
                smbFile?.write( {
                    ( offset ) -> Data? in
                    
                    if offset < data.count {
                        let     blockSize = min( 64000, ( data.count - Int( offset ) ) )
                        let     range     = Range.init( uncheckedBounds: ( lower: Int( offset ), upper: Int( offset ) + blockSize ) )
                        
                        return data.subdata( in: range )
                    }
                    else {
                        return nil
                    }
                    
                }, progress: {
                    ( bytesWrittenTotal, bytesWrittenLast, complete, error ) in
                    
                    if error != nil {
                        logVerbose( "ERROR!  [ %@ ][ %@ ]", fullPath, error?.localizedDescription ?? "Unknown Error" )
                        writeSuccessful = false
                    }
//                    else {
//                        let     progress = 100.0 * ( Float( bytesWrittenTotal ) / Float( data.count ) )
//
//                        logVerbose( "Bytes written[ %ld ] ... total written[ %llu ][ %3.0f%% ]", bytesWrittenLast, bytesWrittenTotal, progress )
//                    }
                    
                    if complete {
//                        logVerbose( "[ %@! ] [ %@ ]", ( writeSuccessful ? "Successful" : "Failed"), path )
                        
                        smbFile?.close( {
                            (error) in
                            
                            if error != nil {
                                logVerbose( "ERROR!  close failed!  [ %@ ][ %@ ]", fullPath, error?.localizedDescription ?? "Unknown Error" )
                                writeSuccessful = false
                            }
                            
                            delegate.smbCentral( self, didSaveData: writeSuccessful )
                        })
                        
                    }
                    
                })
                
            }
            
        } )
        
    }
            
            

}



