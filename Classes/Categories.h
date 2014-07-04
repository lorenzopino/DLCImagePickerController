//
//  NSDictionary+Categories.h
//  AuthProject
//
//  Created by Marco Sanson on 10/4/12.
//  Copyright (c) 2012 D-still Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NYXImagesHelper.h"


@interface NSDictionary (Categories)
- (NSString *)queryString;
@end

@interface UIImage (DrawImage)

+ (UIImage *) bitmapFromRetinaImage:(UIImage *)img;

+ (UIImage *) drawImageFromView:(UIView *)contentView;

+ (UIImage *)radialGradientImageWithSize:(CGSize)size
                                 corners:(UIRectCorner)corners
                                   radii:(CGSize)radii
                                  colors:(NSArray *)colors
                               locations:(NSArray *)locations;

+ (UIImage *)gradientImageWithSize:(CGSize)size
                           corners:(UIRectCorner)corners
                             radii:(CGSize)radii
                            colors:(NSArray *)colors
                         locations:(NSArray *)locations
                        startPoint:(CGPoint)start
                          endPoint:(CGPoint)end;

+ (UIImage *) imageFromColor:(UIColor *)color
                        rect:(CGRect)rect
                     corners:(UIRectCorner)corners
                       radii:(CGSize)radii;

@end

@interface UIImage (PrintBackground)
+ (UIImage *) returnImageFromView:(UIView *)view withRect:(CGRect)rect;
+ (UIImage *) rotateImage:(UIImage *)image;
@end

@interface NSDate (JSONDate)

+ (NSDate *) dateFromJSONDate:(NSString *)date;
+ (NSDate *) dateToGMT:(NSDate *)sourceDate;
+ (NSString *) dateToJSONDate:(NSDate *)date;
+ (NSDate *) birthNSDateFromString:(NSString *)date;

@end

@interface NSObject (StringValidation)
- (BOOL)isValidObject;
- (BOOL)isValidString;
@end

@interface UIColor (RandomColor)
+ (UIColor *)randomColor;
+ (UIColor *)randomColorWithLimit:(int)limit;
@end

@interface NSString (linkString)
- (NSString *)bodyOfLink;
@end

@interface UIImage(ResizeCategory)
-(UIImage*)resizedImageToSize:(CGSize)dstSize;
-(UIImage*)resizeImageToSize:(CGSize)dstSize andScale:(CGFloat)scale;
-(UIImage*)resizedImageToFitInSize:(CGSize)boundingSize scaleIfSmaller:(BOOL)scale;
-(UIImage*)resizedImageToFitInSize:(CGSize)boundingSize scaleIfSmaller:(BOOL)scaleIfSmaller andScale:(CGFloat)scale;
@end

typedef enum
{
    NYXCropModeTopLeft,
    NYXCropModeTopCenter,
    NYXCropModeTopRight,
    NYXCropModeBottomLeft,
    NYXCropModeBottomCenter,
    NYXCropModeBottomRight,
    NYXCropModeLeftCenter,
    NYXCropModeRightCenter,
    NYXCropModeCenter
} NYXCropMode;

typedef enum
{
    NYXResizeModeScaleToFill,
    NYXResizeModeAspectFit,
    NYXResizeModeAspectFill
} NYXResizeMode;


@interface UIImage (NYX_Resizing)

-(UIImage*)cropToSize:(CGSize)newSize usingMode:(NYXCropMode)cropMode;

// NYXCropModeTopLeft crop mode used
-(UIImage*)cropToSize:(CGSize)newSize;

-(UIImage*)scaleByFactor:(float)scaleFactor;

-(UIImage*)scaleToSize:(CGSize)newSize usingMode:(NYXResizeMode)resizeMode;

// NYXResizeModeScaleToFill resize mode used
-(UIImage*)scaleToSize:(CGSize)newSize;

// Same as 'scale to fill' in IB.
-(UIImage*)scaleToFillSize:(CGSize)newSize;

// Preserves aspect ratio. Same as 'aspect fit' in IB.
-(UIImage*)scaleToFitSize:(CGSize)newSize;

// Preserves aspect ratio. Same as 'aspect fill' in IB.
-(UIImage*)scaleToCoverSize:(CGSize)newSize;

@end




