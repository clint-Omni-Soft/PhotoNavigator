//
//  GlobalDefinitions.swift
//  PhotoNavigator
//
//  Created by Clint Shank on 7/22/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


// MARK: Public Variables & Definitions

enum DataLocation {
    case device
    case nas
    case notAssigned
    case shareNas
}

struct DataLocationName {
    static let device       = "device"
    static let nas          = "nas"
    static let notAssigned  = "notAssigned"
    static let shareNas     = "shareNas"
}

struct DirectoryNames {
    static let root       = "PhotoNavigator"
    static let pictures   = "Photos"
}

struct EntityNames {
    static let imageRequest   = "ImageRequest"
    static let mediaFile      = "MediaFile"
    static let photoAssets    = "PhotoAssets"
}

struct Filenames {
    static let database    = "PhotoNavigatorDB.sqlite"
    static let databaseShm = "PhotoNavigatorDB.sqlite-shm"
    static let databaseWal = "PhotoNavigatorDB.sqlite-wal"
    static let exportedCsv = "PhotoNavigator.csv"
    static let lastUpdated = "LastUpdated"
    static let lockFile    = "LockFile"
}

struct GlobalConstants {
    static let sortByCreationDate               = "creationDate"
    static let dataFileExtension                = ".dat"
    static let fileExtensionSeparator           = "."
    static let filePathSeparator                = "/"
    static let groupedTableViewBackgroundColor  = UIColor.init( red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0 )
    static let newMediaFile                     = -1
    static let noGuid                           = "No GUID"
    static let noSelection                      = -1
    static let notSet                           = Int16( -4 )
    static let lightBlueColor                   = UIColor.init( red: 153/255, green: 204/255, blue: 255/255, alpha: 1.0 )
    static let noImage                          = "noImage"
    static let offlineColor                     = UIColor.init( red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0 )
    static let onlineColor                      = UIColor.init( red: 204/255, green: 255/255, blue: 204/255, alpha: 1.0 )
    static let paleYellowColor                  = UIColor.init( red: 255/255, green: 255/255, blue: 204/255, alpha: 1.0 )
    static let separatorForIdentifierString     = ","
    static let separatorForLastUpdatedString    = ","
    static let separatorForLockfileString       = ","
    static let separatorForSorts                = ";"
    static let sortAscending                    = "↑"    // "▴"
    static let sortAscendingFlag                = "A"
    static let sortDescending                   = "↓"    // "▾"
    static let sortDescendingFlag               = "D"
    static let supportedFilenameExtensions      = ["AVI", "JPEG", "JPG", "HEIC", "HEIF", "HTM", "HTML", "MOV", "MP4", "MPEG", "MPEG4", "PNG", "QT", "TIF", "TIFF", "TS", "WEBM", "WEBP", "WMV"]
    static let imageFilenameExtensions          = ["JPEG", "JPG", "HEIC", "HEIF", "PNG", "TIF", "TIFF"]
    static let videoFilenameExtensions          = ["AVI", "MOV", "MP4", "MPEG", "MPEG4", "QT", "TS", "WEBP", "WMV"]
    static let webFilenameExtensions            = ["HTM", "HTML", "WEBP"]
}

struct GlobalIndexPaths {
    static let newMediaFile = IndexPath(row: GlobalConstants.newMediaFile, section: GlobalConstants.newMediaFile )
    static let noSelection  = IndexPath(row: GlobalConstants.noSelection,  section: GlobalConstants.noSelection  )
}

struct FileMimeTypes {
    static let avi   = "video/x-msvideo"
    static let jpeg  = "image/jpeg"
    static let jpg   = "image/jpeg"
    static let heic  = "image.heic"
    static let heif  = "image.heic"
    static let htm   = "text/html"
    static let html  = "text/html"
    static let mov   = "video/quicktime"
    static let mp4   = "video/mp4"
    static let mpeg  = "video/mpeg"
    static let mpeg4 = "video/mp4"
    static let png   = "image/png"
    static let qt    = "video/quicktime"
    static let tif   = "image/tiff"
    static let tiff  = "image/tiff"
    static let ts    = "video/mp2t"
    static let webm  = "image/webm"
    static let webp  = "image/webp"
    static let wmv   = "video/x-ms-wmv"
    static let unsup = "unsupported"
}

struct Notifications {
    static let cannotReadAllDbFiles         = "CannotReadAllDbFiles"
    static let cannotSeeExternalDevice      = "CannotSeeExternalDevice"
    static let connectingToExternalDevice   = "ConnectingToExternalDevice"
    static let deviceAssetsReloaded         = "DeviceAssetsReloaded"
    static let deviceNameNotSet             = "DeviceNameNotSet"
    static let enteringBackground           = "EnteringBackground"
    static let enteringForeground           = "EnteringForeground"
    static let externalDeviceLocked         = "ExternalDeviceLocked"
    static let mediaDataReloaded            = "MediaDataReloaded"
    static let ready                        = "Ready"
    static let repoScanRequested            = "RepoScanRequested"
    static let transferringDatabase         = "TransferringDatabase"
    static let unableToConnect              = "UnableToConnect"
    static let updatingExternalDevice       = "UpdatingExternalDevice"
}

struct SortOptions {
    static let byFilename     = "byFilename"
    static let byRelativePath = "byRelativePath"
}

struct SortOptionNames {
    static let byFilename     = NSLocalizedString( "SortOption.Filename",     comment: "Filename"      )
    static let byRelativePath = NSLocalizedString( "SortOption.RelativePath", comment: "Relative Path" )
}

struct SupportedFilenameExtensions {
    static let avi   = GlobalConstants.supportedFilenameExtensions[0]
    static let jpeg  = GlobalConstants.supportedFilenameExtensions[1]
    static let jpg   = GlobalConstants.supportedFilenameExtensions[2]
    static let heic  = GlobalConstants.supportedFilenameExtensions[3]
    static let heif  = GlobalConstants.supportedFilenameExtensions[4]
    static let htm   = GlobalConstants.supportedFilenameExtensions[5]
    static let html  = GlobalConstants.supportedFilenameExtensions[6]
    static let mov   = GlobalConstants.supportedFilenameExtensions[7]
    static let mp4   = GlobalConstants.supportedFilenameExtensions[8]
    static let mpeg  = GlobalConstants.supportedFilenameExtensions[9]
    static let mpeg4 = GlobalConstants.supportedFilenameExtensions[10]
    static let png   = GlobalConstants.supportedFilenameExtensions[11]
    static let qt    = GlobalConstants.supportedFilenameExtensions[12]
    static let tif   = GlobalConstants.supportedFilenameExtensions[13]
    static let tiff  = GlobalConstants.supportedFilenameExtensions[14]
    static let ts    = GlobalConstants.supportedFilenameExtensions[15]
    static let webm  = GlobalConstants.supportedFilenameExtensions[16]
    static let webp  = GlobalConstants.supportedFilenameExtensions[17]
    static let wmv   = GlobalConstants.supportedFilenameExtensions[18]
}

struct UserDefaultKeys {
    static let currentSortOption         = "CurrentSortOption"
    static let dataSourceDescriptor      = "DataSourceDescriptor"
    static let dataSourceLocation        = "DataSourceLocation"
    static let dataStoreDescriptor       = "DataStoreDescriptor"
    static let dataStoreLocation         = "DataStoreLocation"
    static let deviceName                = "DeviceName"
    static let dontRemindMeAgain         = "DontRemindMeAgain"
    static let howToUseShown             = "HowToUseShown"
    static let imageDuration             = "ImageDuration"
    static let lastAccessedMediaFileGuid = "LastAccessedMediaFileGuid"
    static let lastTabSelected           = "LastTabSelected"
    static let networkAccessGranted      = "NetworkAccessGranted"
    static let networkPath               = "NetworkPath"
    static let updatedOffline            = "UpdatedOffline"
}

