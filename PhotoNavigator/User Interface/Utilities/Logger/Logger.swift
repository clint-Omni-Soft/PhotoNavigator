//
//  Logger.swift
//  ClubLengths
//
//  Copied from WineStock by Clint Shank on 1/6/2023.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit



// MARK: Global Logging Methods (Public)

func logContents() -> String {
    var     contentsText = ""
    let     logFileUrl   = LogCentral.sharedInstance.getLogFileUrl()
    
    do {
        contentsText = try String(contentsOf: logFileUrl, encoding: .utf8)
    }
    catch {
        contentsText = String( format: "Unable to read logfile at [ %@ ]", logFileUrl.path )
    }

    return contentsText
}


func logTrace( filename   : String = #file,
               function   : String = #function,
               lineNumber : Int    = #line,
               _ message  : String = "" ) {
    let     logCentral = LogCentral.sharedInstance
    var     output     = logCentral.timeAndLocation( filename, function, lineNumber )
 
    if !message.isEmpty {
        output += " - " + message
    }

    logCentral.log( output )
}


func logVerbose( filename   : String = #file,
                 function   : String = #function,
                 lineNumber : Int    = #line,
                 _ format   : String,
                 _ args     : CVarArg... ) {
//  var     message    = String( format: format, args )    // NOTE: This doesn't work with multiple args yet ... maybe in a future version of Swift
    let     logCentral = LogCentral.sharedInstance
    let     message    = logCentral.populateFormat( format, args )
    var     output     = logCentral.timeAndLocation( filename, function, lineNumber )

    if !message.isEmpty {
        output += " - " + ( message as String )
    }

    logCentral.log( output )
}





// MARK: LogCentral Class Declaration

class LogCentral : NSObject {

    // MARK: Our Singleton
    
    static let sharedInstance = LogCentral()        // Prevents anyone else from creating an instance
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
    static let appName               = "CFBundleName"
    static let buildVersion          = "CFBundleShortVersionString"
    static let logDirectoryName      = "Logs"
    static let maxFileSize           = UInt64( 5242880 )   // 5 Mb
    static let maxNumberOfLogFiles   = 4
    static let runCounterKey         = "RunCounter"
    static let reachedStreamCapacity = 0
    static let userDefaultsKey       = "CurrentLogFileName"
    static let writeFailed           = -1
    }
    
    private let fileManager         = FileManager.default
    private var logFileSize: UInt64 = 0
    private var logFileOpen         = false
    private var logFileUrl: URL!
    private var outputStream: OutputStream!


    
   // MARK: AppDelegate Methods

    func setupLogging() {
        if currentLogFileOpened() {
            logFileOpen = true
        }
        else {
            print( "LogCentral::setupLogging()\n\n     >>> ERROR!  Unable to start file logging! <<< \n\n" )
        }
      
        log( headerText() )
    }



    // MARK: Primary Interface Methods
    
    func getLogFileUrl() -> URL {
        return logFileUrl
    }
    
    
    func log(_ message : String ) {
        print( message )
        
        if !logFileOpen {
            return
        }
        
        let     buffer       = message + "\n"
        let     bytesWritten = outputStream.write( buffer, maxLength: buffer.count )
        
        if bytesWritten == Constants.writeFailed {
            print( "LogCentral::log() - ERROR!  Unable to write to stream" )
        }
        else if bytesWritten == Constants.reachedStreamCapacity {
            print( "LogCentral::log() - ERROR!  Reached stream capacity" )
        }
        else {
            logFileSize += UInt64( bytesWritten )
            
            if logFileSize > Constants.maxFileSize {
                outputStream.close()
                UserDefaults.standard.removeObject( forKey: Constants.userDefaultsKey )
                
                if currentLogFileOpened() {
                    logFileOpen = true
                }
                else {
                    print( "LogCentral::log() - ERROR!  Unable to open new log file!" )
                }
                
                DispatchQueue.global().async {
                    self.monitorLogFiles()
                }
                
            }
            
        }
            
    }


    func populateFormat(_ format   : String,
                        _ argArray : [CVarArg] ) -> String {
        var     argIndex         = 0
        var     componentIndex   = 0
        let     formatComponents = format.components(separatedBy: "%" )
        var     outputString     = ""
        
        for component in formatComponents {

            // NOTE: We are making the assumption that the format does not start with a % sign
            //       We need at least 1 character before the first % sign
            
            if componentIndex == 0 {
                outputString += component
            }
            else {
                let     formatString    = "%" + component
                let     populatedString = String( format: formatString, argArray[argIndex] )
                    
                outputString += populatedString
                argIndex += 1
            }
            
            componentIndex += 1
        }
        
        return outputString
    }
    
    
    func timeAndLocation(_ filename   : String,
                         _ function   : String,
                         _ lineNumber : Int ) -> String {
        let     dateFormatter    = DateFormatter.init()
        let     fileUrl          = URL( fileURLWithPath: filename )
        let     lastUrlComponent = fileUrl.lastPathComponent
        let     fileComponents   = lastUrlComponent.components(separatedBy: "." )
        var     rootFilename     = lastUrlComponent
        
        if fileComponents.count == 2 {
            rootFilename = fileComponents[0]
        }
        
        dateFormatter.dateFormat = "MM-dd-YYYY HH:mm:ss:SSS z"

        return String( format : "%@ %@::%@[ %d ]", dateFormatter.string( from : Date() ), rootFilename, function, lineNumber )
    }
    
    
    
    // MARK: Utility Methods
    
    private func currentLogFileOpened() -> Bool {
        let     logFilePath = logsDirectoryPath()
          
        logFileOpen = false
        logFileSize = 0
        logFileUrl  = nil

        if logFilePath.isEmpty {
           return false
        }
          
        var currentLogFileName = ""
        
        if let logFileName = UserDefaults.standard.object( forKey: Constants.userDefaultsKey ) {
            currentLogFileName = logFileName as! String
        }
          
        if currentLogFileName.isEmpty {
           currentLogFileName = newLogFileName()
        }
          
        var     logUrl    = URL( fileURLWithPath: logFilePath )
        var     logOpened = false

        logUrl.appendPathComponent( currentLogFileName )
        
        // Create the file if it does not exist
        if !fileManager.fileExists( atPath: logUrl.path ) {
            
            if !fileManager.createFile( atPath: logUrl.path, contents: nil, attributes: nil ) {
                print( "LogCentral::currentLogFileOpened() - ERROR!  Unable to create [ \(logUrl.path) ]" )
                return false
            }
            
        }
        
        // The file exists, now establish a stream and write the header into it
        if let stream = OutputStream( url : logUrl, append : true ) {
            stream.open()
            
            let text         = "\n"
            let bytesWritten = stream.write( text, maxLength: text.count )
            
            if bytesWritten == Constants.writeFailed {
                print( "LogCentral::currentLogFileOpened() - ERROR!  Unable to write to stream to [ \(logUrl.path) ]" )
            }
            else if bytesWritten == Constants.reachedStreamCapacity {
                print( "LogCentral::currentLogFileOpened() - ERROR!  Reached stream capacity for [ \(logUrl.path) ]" )
            }
            else {
                logFileSize  = 0
                logFileUrl   = logUrl
                logOpened    = true
                outputStream = stream
                
                do {
                    let     attributesArray = try fileManager.attributesOfItem( atPath: logUrl.path )

                    logFileSize = attributesArray[FileAttributeKey.size] as! UInt64
                }
                catch {
                    print( "LogCentral::currentLogFileOpened() - ERROR!  Unable to get attributes for [ \(logFileUrl.path) ][ \(error) ]" )
                }
                
            }

        }
        else {
            print( "LogCentral::currentLogFileOpened() - ERROR!  Unable to open stream to [ \(logFileUrl.path) ]" )
        }
            
        return logOpened
    }


    private func headerText() -> String {
        let     dateFormatter  = DateFormatter.init()
        let     infoDictionary = Bundle.main.infoDictionary!
        let     userDefaults   = UserDefaults.standard
        var     runCounter     = userDefaults.integer(forKey: Constants.runCounterKey )
        let     vendorId       = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        var     deviceName     = UIDevice.current.name

        if let deviceNameString = userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
            if !deviceNameString.isEmpty && deviceNameString.count > 0 {
                deviceName = deviceNameString
            }

        }

        runCounter += 1
        
        userDefaults.set( runCounter, forKey: Constants.runCounterKey )
        userDefaults.synchronize()
        
        dateFormatter.dateFormat = "MM-dd-YYYY HH:mm:ss:SSS z"
        
        let     output = String( format : """
                                          \n>>> Starting OSI Logging <<<\n
                                          Application    %@
                                          Current Time   %@
                                          Device Name    %@
                                          Device UUID    %@
                                          OS Version     %@
                                          Build Version  %@
                                          Environment    %@
                                          Launch Counter %d
                                          Log File Size  %d
                                          Log File Path  %@\n
                                          """,
                                 infoDictionary[Constants.appName] as! String,
                                 dateFormatter.string( from : Date() ),
                                 deviceName,
                                 vendorId,
                                 UIDevice.current.systemVersion,
                                 infoDictionary[Constants.buildVersion] as! String,
                                 UIDevice.current.model,
                                 runCounter,
                                 logFileSize,
                                 logFileUrl.path );
        return output
    }
    
    
    private func logsDirectoryPath() -> String {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     logsDirectoryURL = documentDirectoryURL.appendingPathComponent( Constants.logDirectoryName )
            
            if !fileManager.fileExists( atPath: logsDirectoryURL.path ) {
                do {
                    try fileManager.createDirectory( atPath: logsDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                catch {
                    print( "LogCentral::logsDirectoryPath() - ERROR!  Unable to create[ \(logsDirectoryURL.path) ]" )
                    return ""
                }
                
            }
            
            return logsDirectoryURL.path
        }
        else {
            print( "LogCentral::logsDirectoryPath() - ERROR!  Unable to access document directory!" )
        }
        
        return ""
    }


    private func monitorLogFiles() {
        var     filenameArray : [String] = []
        var     filesDeleted  = 0
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     logFileUrl = documentDirectoryURL.appendingPathComponent( Constants.logDirectoryName )
            
            do {
                try filenameArray = fileManager.contentsOfDirectory( atPath: logFileUrl.path )
                
                print( "LogCentral::monitorLogFiles() - Found [ \(filenameArray.count) ] log files" )
                filenameArray = filenameArray.sorted(by: {
                    (filename1, filename2) -> Bool in
                    
                    filename1 < filename2
                } )
                
                while filenameArray.count >= Constants.maxNumberOfLogFiles {
                    var  logToDeleteUrl = logFileUrl
                    
                    logToDeleteUrl = logToDeleteUrl.appendingPathComponent( filenameArray.first! )
                    
                    do {
                        try fileManager.removeItem( at: logToDeleteUrl )
                        filenameArray.removeFirst()
                        filesDeleted += 1
                    }
                    catch {
                        print( "LogCentral::monitorLogFiles() - ERROR!  Unable to delete[ \(filenameArray.first!) ]" )
                    }
                    
                }

                print( "LogCentral::monitorLogFiles() - Deleted [ \(filesDeleted) ] log files" )
            }
            catch let error as NSError {
                print( "LogCentral::monitorLogFiles() - ERROR!  Unable to get contents of Logs directory [ \(error) ]" )
            }

        }

    }


    private func newLogFileName() -> String {
        let     formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd@HH_mm_ss"

        var     filename = formatter.string( from: Date() )
        
        filename += ".txt"
        
        UserDefaults.standard.set( filename, forKey: Constants.userDefaultsKey )
        UserDefaults.standard.synchronize()
        
        return filename
    }

        
}






