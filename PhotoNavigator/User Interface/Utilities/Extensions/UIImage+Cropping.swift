//
//  UIImage+Cropping.swift
//  ImageCropExample
//
//  Created by Clint Shank on 1/7/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


extension UIImage {
    
    // MARK: Public Methods
    
    func crop(_ cropRect : CGRect, in frame : CGSize ) -> (UIImage, Bool) {
        
        let     frameSize = CGSize.init( width: round( frame.width ), height: round( frame.height ) )
        let     image     = scaleBitmapTo( frameSize )
        
        if let imageRef = image.cgImage!.cropping( to: transpose( cropRect, to: frameSize, in: self.imageOrientation ) ) {
            let     croppedImage = UIImage( cgImage: imageRef, scale: 1.0, orientation: self.imageOrientation )
            
            return (croppedImage, true)
        }
        
        logTrace( "ERROR!  Could not create imageRef from image cropping!" )
        
        return (self, false)
    }
    
    
    func rotate( radians: Float ) -> UIImage? {
        var     newSize = CGRect( origin: CGPoint.zero, size: self.size ).applying( CGAffineTransform( rotationAngle: CGFloat( radians ) ) ).size
        
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width  = floor( newSize.width  )
        newSize.height = floor( newSize.height )

        UIGraphicsBeginImageContextWithOptions( newSize, false, self.scale )
        
        let     context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy( x: newSize.width/2, y: newSize.height/2 )
        
        // Rotate around middle
        context.rotate( by: CGFloat( radians ) )
        
        // Draw the image at its center
        self.draw( in: CGRect( x : -self.size.width/2, y : -self.size.height/2, width : self.size.width, height : self.size.height ) )

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()

        return newImage
    }

    
    
    // MARK: Private Methods
    
    private func scaleBitmapTo(_ toSize : CGSize ) -> UIImage {
        
        if let myImage = self.cgImage {
            var     scaledSize = CGSize.init( width: round( toSize.width ), height: round( toSize.height ) )
            
            // If the underlying CGImage is oriented differently than the UIImage then swap the width and height of the scale size.
            // NOTE: This method assumes the size passed is a request on the UIImage's orientation.
            
            if self.imageOrientation == .left || self.imageOrientation == .right {
                scaledSize = CGSize.init( width: round( scaledSize.height ), height: round( scaledSize.width ) )
            }
            
            // Create a bitmap context in the dimensions of the scale size and draw the underlying CGImage into the context
            if let context = CGContext.init( data              : nil,
                                             width             : Int( scaledSize.width ),
                                             height            : Int( scaledSize.height ),
                                             bitsPerComponent  : myImage.bitsPerComponent,
                                             bytesPerRow       : 0,
                                             space             : myImage.colorSpace!,
                                             bitmapInfo        : myImage.bitmapInfo.rawValue ) {
                
                let     targetRect = CGRect.init( x: 0, y: 0, width: scaledSize.width, height: scaledSize.height )
                
                context.draw( myImage, in: targetRect )
                
                if let cgImage = context.makeImage() {
                    return UIImage.init( cgImage: cgImage )
                }
                else {
                    logTrace( "ERROR!  Unable to convert cgImage to UIImage!" )
                }

            }
            else {
                logTrace( "ERROR!  NULL Bitmap Context in scaleBitmapToSize" )
            }

        }
        else {
            logTrace( "ERROR!  Cannot unwrap self.cgImage!" )
        }

        return UIImage.init()
    }
    
    
    private func transpose(_ cropRect : CGRect, to dimension : CGSize, in orientation : UIImage.Orientation ) -> CGRect {
        var     transposedRect = cropRect
        
        switch orientation {
        case .left:
            transposedRect.origin.x = dimension.height - (cropRect.size.height + cropRect.origin.y)
            transposedRect.origin.y = cropRect.origin.x
            transposedRect.size     = CGSize.init( width: cropRect.size.height, height: cropRect.size.width )
            
        case .right:
            transposedRect.origin.x = cropRect.origin.y
            transposedRect.origin.y = dimension.width - (cropRect.size.width + cropRect.origin.x)
            transposedRect.size     = CGSize.init( width: cropRect.size.height, height: cropRect.size.width)
            
        case .down:
            transposedRect.origin.x = dimension.width  - ( cropRect.size.width  + cropRect.origin.x )
            transposedRect.origin.y = dimension.height - ( cropRect.size.height + cropRect.origin.y )
            
        case .downMirrored:
            transposedRect.origin.x = cropRect.origin.x
            transposedRect.origin.y = dimension.height - ( cropRect.size.height + cropRect.origin.y )
            
        case .leftMirrored:
            transposedRect.origin.x = cropRect.origin.y
            transposedRect.origin.y = cropRect.origin.x
            transposedRect.size     = CGSize.init( width: cropRect.size.height, height: cropRect.size.width)
            break;
            
        case .rightMirrored:
            transposedRect.origin.x = dimension.height - ( cropRect.size.height + cropRect.origin.y )
            transposedRect.origin.y = dimension.width  - ( cropRect.size.width  + cropRect.origin.x )
            transposedRect.size     = CGSize.init( width: cropRect.size.height, height: cropRect.size.width)
            
        case .upMirrored:
            transposedRect.origin.x = dimension.width - ( cropRect.size.width + cropRect.origin.x )
            transposedRect.origin.y = cropRect.origin.y
            
       default:    // .up
            break
        }
        
        return transposedRect
    }

    
}

