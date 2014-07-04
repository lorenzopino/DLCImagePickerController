//
//  NSDictionary+Categories.m
//  AuthProject
//
//  Created by Marco Sanson on 10/4/12.
//  Copyright (c) 2012 D-still Inc. All rights reserved.
//

#import "Categories.h"
#import <QuartzCore/QuartzCore.h>

static NSString * escapeString(NSString *unencodedString)
{
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                      (CFStringRef)unencodedString,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'\"();:@&=+$,/?%#[]%. ",
                                                                      kCFStringEncodingUTF8));
}

@implementation NSDictionary (QueryStringBuilder)


@end

@implementation UIImage (DrawImage)

+ (UIImage *) bitmapFromRetinaImage:(UIImage *)img
{
    CGSize finalSize = (CGSize){ img.size.width * .5, img.size.height * .5 };
    
    UIGraphicsBeginImageContext(finalSize);
    [img drawInRect:(CGRect){0, 0, finalSize}];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *) drawImageFromView:(UIView *)contentView
{
    CGSize viewSize = contentView.frame.size;
    
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2) {
        UIGraphicsBeginImageContextWithOptions(viewSize, NO, 2.0f);
    }else{
        UIGraphicsBeginImageContext(viewSize);
    }
    
    CGContextRef resizedContext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(resizedContext, 0, 0);
    [contentView.layer renderInContext:resizedContext];
    
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


+ (UIImage *) imageFromColor:(UIColor *)color
                        rect:(CGRect)rect
                     corners:(UIRectCorner)corners
                       radii:(CGSize)radii
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetFillColorWithColor(context, [color CGColor]);
//    CGContextFillRect(context, rect);
    UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){0, 0, rect.size.width, rect.size.height}
                                                               byRoundingCorners:corners
                                                                     cornerRadii:radii];
    CGContextSaveGState(context);
    [color setFill];
    [roundedRectanglePath fill];
    [roundedRectanglePath addClip];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

@end

@implementation UIImage (PrintBackground)

+ (UIImage *) returnImageFromView:(UIView *)view withRect:(CGRect)rect
{
    CGSize pageSize = rect.size;
    
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2) {
        UIGraphicsBeginImageContextWithOptions(pageSize, NO, 2.0f);
    }else{
        UIGraphicsBeginImageContext(pageSize);
    }
    
    CGContextRef resizedContext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(resizedContext, -rect.origin.x, 0);
    
    [[view layer] renderInContext:resizedContext];
    
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *) rotateImage:(UIImage *)image
{
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 2.0f);
    }else{
        UIGraphicsBeginImageContext(bounds.size);
    }
    
    CGFloat boundHeight;
    
    boundHeight = bounds.size.height;
    bounds.size.height = bounds.size.width;
    bounds.size.width = boundHeight;
    transform = CGAffineTransformMakeScale(-1.0, 1.0);
    transform = CGAffineTransformRotate(transform, M_PI / 2.0); //use angle/360 *MPI
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

@end

@implementation NSDate (JSONDate)

+ (NSDate *) dateFromJSONDate:(NSString *)date
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SS'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
    return [NSDate dateToGMT:[dateFormatter dateFromString:date]];
}

+ (NSDate *) dateToGMT:(NSDate *)sourceDate
{
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:destinationGMTOffset sinceDate:sourceDate];
    return destinationDate;
}

+ (NSString *) dateToJSONDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SS'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    return [dateFormatter stringFromDate:date];
}

+ (NSDate *) birthNSDateFromString:(NSString *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSRange stringRange = [date rangeOfString:@"/" options:NSCaseInsensitiveSearch];
    if( stringRange.location != NSNotFound ) {
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    } else {
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    
    return [dateFormatter dateFromString:date];
}

@end

@implementation NSObject (ObjectValidation)

- (BOOL)isValidObject
{
    if (self && ![self isEqual:[NSNull null]] && [self isKindOfClass:[NSObject class]]) {
        return YES;
    } else
        return NO;
}

- (BOOL)isValidString
{
    if ([self isValidObject] && [self isKindOfClass:[NSString class]] && ![(NSString *)self isEqualToString:@""]) {
        return YES;
    } else
        return NO;
}

@end

@implementation UIColor (RandomColor)

+ (UIColor *)randomColor
{
    return [self randomColorWithLimit:255];
}

+ (UIColor *)randomColorWithLimit:(int)limit
{
    return [[UIColor alloc] initWithRed:((arc4random()%limit)/255.0f) green:((arc4random()%limit)/255.0f)  blue:((arc4random()%limit)/255.0f) alpha:1];
}

@end

@implementation NSString (linkString)

- (NSString *)bodyOfLink
{
    return [[[[self lowercaseString] stringByReplacingOccurrencesOfString:@"https://" withString:@""] stringByReplacingOccurrencesOfString:@"http://" withString:@""] stringByReplacingOccurrencesOfString:@"www." withString:@""];
}

@end

@implementation UIImage (ResizeCategory)

-(UIImage*)resizeImageToSize:(CGSize)dstSize andScale:(CGFloat)scale{
    UIImage *resizedImage = [self resizedImageToSize:dstSize];
    return [UIImage imageWithCGImage:resizedImage.CGImage scale:scale orientation:resizedImage.imageOrientation];
}

-(UIImage*)resizedImageToSize:(CGSize)dstSize
{
	CGImageRef imgRef = self.CGImage;
	// the below values are regardless of orientation : for UIImages from Camera, width>height (landscape)
	CGSize  srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef)); // not equivalent to self.size (which is dependant on the imageOrientation)!
	
    /* Don't resize if we already meet the required destination size. */
    if (CGSizeEqualToSize(srcSize, dstSize)) {
        return self;
    }
    
	CGFloat scaleRatio = dstSize.width / srcSize.width;
	UIImageOrientation orient = self.imageOrientation;
	CGAffineTransform transform = CGAffineTransformIdentity;
	switch(orient) {
			
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
			
		case UIImageOrientationUpMirrored: //EXIF = 2
			transform = CGAffineTransformMakeTranslation(srcSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
			
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(srcSize.width, srcSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case UIImageOrientationDownMirrored: //EXIF = 4
			transform = CGAffineTransformMakeTranslation(0.0, srcSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
			
		case UIImageOrientationLeftMirrored: //EXIF = 5
			dstSize = CGSizeMake(dstSize.height, dstSize.width);
			transform = CGAffineTransformMakeTranslation(srcSize.height, srcSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI_2);
			break;
			
		case UIImageOrientationLeft: //EXIF = 6
			dstSize = CGSizeMake(dstSize.height, dstSize.width);
			transform = CGAffineTransformMakeTranslation(0.0, srcSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI_2);
			break;
			
		case UIImageOrientationRightMirrored: //EXIF = 7
			dstSize = CGSizeMake(dstSize.height, dstSize.width);
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;
			
		case UIImageOrientationRight: //EXIF = 8
			dstSize = CGSizeMake(dstSize.height, dstSize.width);
			transform = CGAffineTransformMakeTranslation(srcSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
	
	/////////////////////////////////////////////////////////////////////////////
	// The actual resize: draw the image on a new context, applying a transform matrix
	UIGraphicsBeginImageContextWithOptions(dstSize, NO, self.scale);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (!context) {
        return nil;
    }
	
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -srcSize.height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -srcSize.height);
	}
	
	CGContextConcatCTM(context, transform);
	
	// we use srcSize (and not dstSize) as the size to specify is in user space (and we use the CTM to apply a scaleRatio)
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, srcSize.width, srcSize.height), imgRef);
	UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return resizedImage;
}



/////////////////////////////////////////////////////////////////////////////



-(UIImage*)resizedImageToFitInSize:(CGSize)boundingSize scaleIfSmaller:(BOOL)scale
{
	// get the image size (independant of imageOrientation)
	CGImageRef imgRef = self.CGImage;
	CGSize srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef)); // not equivalent to self.size (which depends on the imageOrientation)!
    
	// adjust boundingSize to make it independant on imageOrientation too for farther computations
	UIImageOrientation orient = self.imageOrientation;
	switch (orient) {
		case UIImageOrientationLeft:
		case UIImageOrientationRight:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			boundingSize = CGSizeMake(boundingSize.height, boundingSize.width);
			break;
        default:
            // NOP
            break;
	}
    
	// Compute the target CGRect in order to keep aspect-ratio
	CGSize dstSize;
	
	if ( !scale && (srcSize.width < boundingSize.width) && (srcSize.height < boundingSize.height) ) {
		//NSLog(@"Image is smaller, and we asked not to scale it in this case (scaleIfSmaller:NO)");
		dstSize = srcSize; // no resize (we could directly return 'self' here, but we draw the image anyway to take image orientation into account)
	} else {
		CGFloat wRatio = boundingSize.width / srcSize.width;
		CGFloat hRatio = boundingSize.height / srcSize.height;
		
		if (wRatio < hRatio) {
			//NSLog(@"Width imposed, Height scaled ; ratio = %f",wRatio);
			dstSize = CGSizeMake(boundingSize.width, floorf(srcSize.height * wRatio));
		} else {
			//NSLog(@"Height imposed, Width scaled ; ratio = %f",hRatio);
			dstSize = CGSizeMake(floorf(srcSize.width * hRatio), boundingSize.height);
		}
	}
    
	return [self resizedImageToSize:dstSize];
}

-(UIImage*)resizedImageToFitInSize:(CGSize)boundingSize scaleIfSmaller:(BOOL)scaleIfSmaller andScale:(CGFloat)scale{
    UIImage *resizedImage = [self resizedImageToFitInSize:boundingSize scaleIfSmaller:scaleIfSmaller];
    return [UIImage imageWithCGImage:resizedImage.CGImage scale:scale orientation:resizedImage.imageOrientation];
}

@end

@implementation UIImage (NYX_Resizing)

-(UIImage*)cropToSize:(CGSize)newSize usingMode:(NYXCropMode)cropMode
{
    const CGSize size = self.size;
    CGFloat x, y;
    switch (cropMode)
    {
        case NYXCropModeTopLeft:
            x = y = 0.0f;
            break;
        case NYXCropModeTopCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = 0.0f;
            break;
        case NYXCropModeTopRight:
            x = size.width - newSize.width;
            y = 0.0f;
            break;
        case NYXCropModeBottomLeft:
            x = 0.0f;
            y = size.height - newSize.height;
            break;
        case NYXCropModeBottomCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = size.height - newSize.height;
            break;
        case NYXCropModeBottomRight:
            x = size.width - newSize.width;
            y = size.height - newSize.height;
            break;
        case NYXCropModeLeftCenter:
            x = 0.0f;
            y = (size.height - newSize.height) * 0.5f;
            break;
        case NYXCropModeRightCenter:
            x = size.width - newSize.width;
            y = (size.height - newSize.height) * 0.5f;
            break;
        case NYXCropModeCenter:
            x = (size.width - newSize.width) * 0.5f;
            y = (size.height - newSize.height) * 0.5f;
            break;
        default: // Default to top left
            x = y = 0.0f;
            break;
    }
    
    if (self.imageOrientation == UIImageOrientationLeft || self.imageOrientation == UIImageOrientationLeftMirrored || self.imageOrientation == UIImageOrientationRight || self.imageOrientation == UIImageOrientationRightMirrored)
    {
        CGFloat temp = x;
        x = y;
        y = temp;
    }
    
    CGRect cropRect = CGRectMake(x * self.scale, y * self.scale, newSize.width * self.scale, newSize.height * self.scale);
    
    /// Create the cropped image
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage* cropped = [UIImage imageWithCGImage:croppedImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(croppedImageRef);
    
    return cropped;
}

/* Convenience method to crop the image from the top left corner */
-(UIImage*)cropToSize:(CGSize)newSize
{
    return [self cropToSize:newSize usingMode:NYXCropModeTopLeft];
}

-(UIImage*)scaleByFactor:(float)scaleFactor
{
    CGSize scaledSize = CGSizeMake(self.size.width * scaleFactor, self.size.height * scaleFactor);
    return [self scaleToFillSize:scaledSize];
}

-(UIImage*)scaleToSize:(CGSize)newSize usingMode:(NYXResizeMode)resizeMode
{
    switch (resizeMode)
    {
        case NYXResizeModeAspectFit:
            return [self scaleToFitSize:newSize];
        case NYXResizeModeAspectFill:
            return [self scaleToCoverSize:newSize];
        default:
            return [self scaleToFillSize:newSize];
    }
}

/* Convenience method to scale the image using the NYXResizeModeScaleToFill mode */
-(UIImage*)scaleToSize:(CGSize)newSize
{
    return [self scaleToFillSize:newSize];
}

-(UIImage*)scaleToFillSize:(CGSize)newSize
{
    size_t destWidth = (size_t)(newSize.width * self.scale);
    size_t destHeight = (size_t)(newSize.height * self.scale);
    if (self.imageOrientation == UIImageOrientationLeft
        || self.imageOrientation == UIImageOrientationLeftMirrored
        || self.imageOrientation == UIImageOrientationRight
        || self.imageOrientation == UIImageOrientationRightMirrored)
    {
        size_t temp = destWidth;
        destWidth = destHeight;
        destHeight = temp;
    }
    
    /// Create an ARGB bitmap context
    CGContextRef bmContext = NYXCreateARGBBitmapContext(destWidth, destHeight, destWidth * kNyxNumberOfComponentsPerARBGPixel, NYXImageHasAlpha(self.CGImage));
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Draw the image in the bitmap context
    
    UIGraphicsPushContext(bmContext);
    CGContextDrawImage(bmContext, CGRectMake(0.0f, 0.0f, destWidth, destHeight), self.CGImage);
    UIGraphicsPopContext();
    
    /// Create an image object from the context
    CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
    /// Cleanup
    CGImageRelease(scaledImageRef);
    CGContextRelease(bmContext);
    
    return scaled;
}

-(UIImage*)scaleToFitSize:(CGSize)newSize
{
    /// Keep aspect ratio
    size_t destWidth, destHeight;
    if (self.size.width > self.size.height)
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(self.size.height * newSize.width / self.size.width);
    }
    else
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(self.size.width * newSize.height / self.size.height);
    }
    if (destWidth > newSize.width)
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(self.size.height * newSize.width / self.size.width);
    }
    if (destHeight > newSize.height)
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(self.size.width * newSize.height / self.size.height);
    }
    return [self scaleToFillSize:CGSizeMake(destWidth, destHeight)];
}

-(UIImage*)scaleToCoverSize:(CGSize)newSize
{
    size_t destWidth, destHeight;
    CGFloat widthRatio = newSize.width / self.size.width;
    CGFloat heightRatio = newSize.height / self.size.height;
    /// Keep aspect ratio
    if (heightRatio > widthRatio)
    {
        destHeight = (size_t)newSize.height;
        destWidth = (size_t)(self.size.width * newSize.height / self.size.height);
    }
    else
    {
        destWidth = (size_t)newSize.width;
        destHeight = (size_t)(self.size.height * newSize.width / self.size.width);
    }
    return [self scaleToFillSize:CGSizeMake(destWidth, destHeight)];
}

@end


