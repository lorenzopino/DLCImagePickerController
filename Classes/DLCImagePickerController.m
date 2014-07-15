//
//  DLCImagePickerController.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/14/12.
//  Copyright (c) 2012 Dmitri Cherniak. All rights reserved.
//

#import "DLCImagePickerController.h"
#import "DLCGrayscaleContrastFilter.h"
#import "FullScreenImagePickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FilterThumbnailView.h"
#import "Categories.h"


#define kStaticBlurSize 2.0f

#define isIOS6 floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1
#define isIOS7 floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1

#define DEFAULT_MIN_PHOTO_SIZE 480.0

#define DEFAULT_MAX_PHOTO_SIZE 2048.0



@implementation DLCImagePickerController {
    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageOutput<GPUImageInput> *blurFilter;
    GPUImageCropFilter *cropFilter;
    GPUImagePicture *staticPicture;
    UIImageOrientation staticPictureOriginalOrientation;
    BOOL isStatic;
    BOOL hasBlur;
    int selectedFilter;
    dispatch_once_t showLibraryOnceToken;
    FilterThumbnailView *noFilterButton;
    PhotoSourceType photoSourceType;
}

@synthesize delegate,
    imageView,
    cameraToggleButton,
    photoCaptureButton,
    blurToggleButton,
    flashToggleButton,
    cancelButton,
    retakeButton,
    filtersToggleButton,
    libraryToggleButton,
    filterScrollView,
    filtersBackgroundImageView,
    photoBar,
    topBar,
    blurOverlayView,
    outputJPEGQuality,
    requestedImageSize;

-(void) sharedInit {
	outputJPEGQuality = 1.0;
	requestedImageSize = CGSizeZero;
    _blurToggleEnabled = YES;
    _flashToggleEnabled = YES;
    _filtersToggleEnabled = YES;
    _libraryToggleEnabled = YES;
    _cameraToggleEnabled = YES;
    _maxPhotoSize = DEFAULT_MAX_PHOTO_SIZE;
    _minPhotoSize = DEFAULT_MIN_PHOTO_SIZE;
    
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self sharedInit];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self sharedInit];
	}
	return self;
}

-(id) init {
    return [self initWithNibName:@"DLCImagePicker" bundle:nil];
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    cameraToggleButton.hidden = !_cameraToggleEnabled;
    blurToggleButton.hidden = !_blurToggleEnabled;
    filtersToggleButton.hidden = !_filtersToggleEnabled;
    libraryToggleButton.hidden = !_libraryToggleEnabled;
    flashToggleButton.hidden = !_flashToggleEnabled;

    self.wantsFullScreenLayout = YES;
    //set background color
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"micro_carbon"]];
    
    //self.photoBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"photo_bar"]];
    
    //self.topBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"photo_bar"]];
    //button states
    [self.blurToggleButton setSelected:NO];
    [self.filtersToggleButton setSelected:NO];
    
    staticPictureOriginalOrientation = UIImageOrientationUp;
    
    self.focusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus-crosshair"]];
	[self.view addSubview:self.focusView];
	self.focusView.alpha = 0;
    
    
    self.blurOverlayView = [[DLCBlurOverlayView alloc] initWithFrame:CGRectMake(0, 0,
																				self.imageView.frame.size.width,
																				self.imageView.frame.size.height)];
    self.blurOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blurOverlayView.alpha = 0;
    [self.imageView addSubview:self.blurOverlayView];
    
    hasBlur = NO;
    
    [self loadFilters];
    
    //we need a crop filter for the live video
    cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0f, 0.0f, 1.0f, 0.75f)];
    
    filter = [[GPUImageFilter alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self setUpCamera];
    });
}

-(void) viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [super viewWillAppear:animated];
    [self updateLastPhotoThumbnail];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        dispatch_once(&showLibraryOnceToken, ^{
            [self switchToLibrary:nil];
        });
    }
}

-(void) loadFilters {
   for(int i = 0; i < 10; i++) {
        FilterThumbnailView *button = [[FilterThumbnailView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i + 1]] andIndex:i];
       if (i == 0) {
           noFilterButton = button;
       }
        CGRect rect = CGRectMake((THUMBS_PADDING+i*(THUMBS_WIDTH+THUMBS_PADDING)), (self.filterScrollView.frame.size.height-button.frame.size.height)/2, button.frame.size.width, button.frame.size.height);
        button.frame = rect;
       
        UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(filterClicked:)];
        [button addGestureRecognizer:tapRec];
        
        if(i == 0){
            [button showBorder:YES];
        }
		[self.filterScrollView addSubview:button];
	}
	[self.filterScrollView setContentSize:CGSizeMake(10 + 10*(60+10), 75.0)];
}


-(void) setUpCamera {
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // Has camera
        
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
                
        stillCamera.horizontallyMirrorFrontFacingCamera = YES;

        stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        runOnMainQueueWithoutDeadlocking(^{
            [stillCamera startCameraCapture];
            if([stillCamera.inputCamera hasTorch]){
                [self.flashToggleButton setEnabled:YES];
            }else{
                [self.flashToggleButton setEnabled:NO];
            }
            [self prepareFilter];
        });
    } else {
        runOnMainQueueWithoutDeadlocking(^{
            // No camera awailable, hide camera related buttons and show the image picker
            self.cameraToggleButton.hidden = YES;
            self.photoCaptureButton.hidden = YES;
            self.flashToggleButton.hidden = YES;
            // Show the library picker
//            [self switchToLibrary:nil];
//            [self performSelector:@selector(switchToLibrary:) withObject:nil afterDelay:0.5];
            [self prepareFilter];
        });
    }
   
}

-(void) filterClicked:(UITapGestureRecognizer *) sender {
    UIView *selectedFilterView = sender.view;
    [self selectFilter:selectedFilterView];

}

- (void) didtapOnThumbnail: (UITapGestureRecognizer *)recognizer{
}

-(void) selectFilter:(UIView*)thumb{
    [self removeAllTargets];
    for(FilterThumbnailView *t in self.filterScrollView.subviews){
        if (t == thumb) {
            [t showBorder:YES];
            selectedFilter = thumb.tag;
            [self setFilter:thumb.tag];
            [self prepareFilter];
            CGPoint scrollTo = CGPointMake(t.center.x - self.filterScrollView.frame.size.width/2, 0);
            if (scrollTo.x >= 0 && scrollTo.x <= self.filterScrollView.contentSize.width - self.filterScrollView.frame.size.width) {
                [self.filterScrollView setContentOffset:CGPointMake(t.center.x - self.filterScrollView.frame.size.width/2, 0) animated:YES];
            }else if(scrollTo.x < 0){
                [self.filterScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
            }else if (scrollTo.x > self.filterScrollView.contentSize.width - self.filterScrollView.frame.size.width){
                [self.filterScrollView setContentOffset:CGPointMake(self.filterScrollView.contentSize.width - self.filterScrollView.frame.size.width, 0) animated:YES];
            }
        }else{
            [t showBorder:NO];
        }
    }
    

}



-(void) setFilter:(int) index {
    switch (index) {
        case 1:{
            filter = [[GPUImageContrastFilter alloc] init];
            [(GPUImageContrastFilter *) filter setContrast:1.75];
        } break;
        case 2: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"crossprocess"];
        } break;
        case 3: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
        } break;
        case 4: {
            filter = [[DLCGrayscaleContrastFilter alloc] init];
        } break;
        case 5: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
        } break;
        case 6: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
        } break;
        case 7: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"yellow-red"];
        } break;
        case 8: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
        } break;
        case 9: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"purple-green"];
        } break;
        default:
            filter = [[GPUImageFilter alloc] init];
            break;
    }
}

-(void) prepareFilter {    
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        isStatic = YES;
    }
    
    if (!isStatic) {
        [self prepareLiveFilter];
    } else {
        [self prepareStaticFilter];
    }
}

-(void) prepareLiveFilter {
    
    [stillCamera addTarget:cropFilter];
    [cropFilter addTarget:filter];
    //blur is terminal filter
    if (hasBlur) {
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
    //regular filter is terminal
    } else {
        [filter addTarget:self.imageView];
    }
    
    [filter useNextFrameForImageCapture];
    
}

-(void) prepareStaticFilter {
    
    [staticPicture addTarget:filter];

    // blur is terminal filter
    if (hasBlur) {
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
    //regular filter is terminal
    } else {
        [filter addTarget:self.imageView];
    }
    
    GPUImageRotationMode imageViewRotationMode = kGPUImageNoRotation;
    switch (staticPictureOriginalOrientation) {
        case UIImageOrientationLeft:
            imageViewRotationMode = kGPUImageRotateLeft;
            break;
        case UIImageOrientationRight:
            imageViewRotationMode = kGPUImageRotateRight;
            break;
        case UIImageOrientationDown:
            imageViewRotationMode = kGPUImageRotate180;
            break;
        default:
            imageViewRotationMode = kGPUImageNoRotation;
            break;
    }
    
    // seems like atIndex is ignored by GPUImageView...
    [self.imageView setInputRotation:imageViewRotationMode atIndex:0];

    
    [staticPicture processImage];
}

-(void) removeAllTargets {
    [stillCamera removeAllTargets];
    [staticPicture removeAllTargets];
    [cropFilter removeAllTargets];
    
    //regular filter
    [filter removeAllTargets];
    
    //blur
    [blurFilter removeAllTargets];
}

-(IBAction)switchToLibrary:(id)sender {
    
    if (!isStatic) {
        // shut down camera
        [stillCamera stopCameraCapture];
        [self removeAllTargets];
    }
    
    FullScreenImagePickerController* imagePickerController = [[FullScreenImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    [imagePickerController setWantsFullScreenLayout:YES];
    [self presentViewController:imagePickerController animated:YES completion:NULL];
}

#ifdef __IPHONE_7_0
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (isIOS7) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
}
#endif



-(IBAction)toggleFlash:(UIButton *)button{
    [button setSelected:!button.selected];
}

-(IBAction) toggleBlur:(UIButton*)blurButton {
    
    [self.blurToggleButton setEnabled:NO];
    [self removeAllTargets];
    
    if (hasBlur) {
        hasBlur = NO;
        [self showBlurOverlay:NO];
        [self.blurToggleButton setSelected:NO];
    } else {
        if (!blurFilter) {
            blurFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setExcludeCircleRadius:80.0/320.0];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setBlurRadiusInPixels:kStaticBlurSize];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setAspectRatio:1.0f];
        }
        hasBlur = YES;
        CGPoint excludePoint = [(GPUImageGaussianSelectiveBlurFilter*)blurFilter excludeCirclePoint];
		CGSize frameSize = self.blurOverlayView.frame.size;
		self.blurOverlayView.circleCenter = CGPointMake(excludePoint.x * frameSize.width, excludePoint.y * frameSize.height);
        [self.blurToggleButton setSelected:YES];
        [self flashBlurOverlay];
    }
    
    [self prepareFilter];
    [self.blurToggleButton setEnabled:YES];
}

-(IBAction) switchCamera {
    
    [self.cameraToggleButton setEnabled:NO];
    [stillCamera rotateCamera];
    [self.cameraToggleButton setEnabled:YES];
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] && stillCamera) {
        if ([stillCamera.inputCamera hasFlash] && [stillCamera.inputCamera hasTorch]) {
            [self.flashToggleButton setEnabled:YES];
        } else {
            [self.flashToggleButton setEnabled:NO];
        }
    }
}

-(void) prepareForCapture {
    [stillCamera.inputCamera lockForConfiguration:nil];
    if(self.flashToggleButton.selected &&
       [stillCamera.inputCamera hasTorch]){
        [stillCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        [self performSelector:@selector(captureImage)
                   withObject:nil
                   afterDelay:0.25];
    }else{
        [self performSelector:@selector(captureImage)
                   withObject:nil
                   afterDelay:0.1];
    }
}


-(void)captureImage {
    
    void (^completion)(UIImage *, NSError *) = ^(UIImage *img, NSError *error) {
        
        [stillCamera.inputCamera unlockForConfiguration];
        [stillCamera stopCameraCapture];
        [self removeAllTargets];
        
        staticPicture = [[GPUImagePicture alloc] initWithImage:img smoothlyScaleOutput:NO];
        staticPictureOriginalOrientation = img.imageOrientation;
        
        [self prepareFilter];
        [self.retakeButton setHidden:NO];
        [self.photoCaptureButton setTitle:@"OK" forState:UIControlStateNormal];
        [self.photoCaptureButton setImage:nil forState:UIControlStateNormal];
        [self.photoCaptureButton setEnabled:YES];
        if(![self.filtersToggleButton isSelected]){
            [self showFilters];
        }
    };
    
    
    //Commentato if per fixare crash su acquisizione con fotocamera centrale
    
    //AVCaptureDevicePosition currentCameraPosition = stillCamera.inputCamera.position;
    //Class contextClass = NSClassFromString(@"GPUImageContext") ?: NSClassFromString(@"GPUImageOpenGLESContext");
    //if ((currentCameraPosition != AVCaptureDevicePositionFront) || (![contextClass supportsFastTextureUpload])) {
        // Image full-resolution capture is currently possible just on the final (destination filter), so
        // create a new paralel chain, that crops and resizes our image
        [self removeAllTargets];
        
        GPUImageCropFilter *captureCrop = [[GPUImageCropFilter alloc] initWithCropRegion:cropFilter.cropRegion];
        [stillCamera addTarget:captureCrop];
        GPUImageFilter *finalFilter = captureCrop;
        
        if (!CGSizeEqualToSize(requestedImageSize, CGSizeZero)) {
            GPUImageFilter *captureResize = [[GPUImageFilter alloc] init];
            [captureResize forceProcessingAtSize:requestedImageSize];
            [captureCrop addTarget:captureResize];
            finalFilter = captureResize;
        }
        
        [finalFilter useNextFrameForImageCapture];
        
        [stillCamera capturePhotoAsImageProcessedUpToFilter:finalFilter withCompletionHandler:completion];
    /*} else {
        // A workaround inside capturePhotoProcessedUpToFilter:withImageOnGPUHandler: would cause the above method to fail,
        // so we just grap the current crop filter output as an aproximation (the size won't match trough)
        
        UIImage *img = [cropFilter imageFromCurrentFramebufferWithOrientation:staticPictureOriginalOrientation];

        completion(img, nil);
    }*/
}


-(IBAction) takePhoto:(id)sender{
    [self.photoCaptureButton setEnabled:NO];
    
    if (!isStatic) {
        photoSourceType = PhotoSourceTypeCamera;
        isStatic = YES;
        
        [self.libraryToggleButton setHidden:YES];
        [self.cameraToggleButton setHidden:YES];
        [self.flashToggleButton setHidden:YES];
        [self prepareForCapture];
        
    } else {
        
        GPUImageOutput<GPUImageInput> *processUpTo;
        
        if (hasBlur) {
            processUpTo = blurFilter;
        } else {
            processUpTo = filter;
        }
        
        [staticPicture addTarget:processUpTo];
        [processUpTo useNextFrameForImageCapture];
        [staticPicture processImage];
        
        UIImage *currentFilteredVideoFrame = [processUpTo imageFromCurrentFramebufferWithOrientation:staticPictureOriginalOrientation];
        
        if (MAX(currentFilteredVideoFrame.size.width, currentFilteredVideoFrame.size.height) > _maxPhotoSize) {
            if (currentFilteredVideoFrame.size.width >= currentFilteredVideoFrame.size.height) {
                currentFilteredVideoFrame = [currentFilteredVideoFrame resizedImageToSize:CGSizeMake(_maxPhotoSize, _maxPhotoSize*(currentFilteredVideoFrame.size.height/currentFilteredVideoFrame.size.width))];
            }else{
                currentFilteredVideoFrame = [currentFilteredVideoFrame resizedImageToSize:CGSizeMake(_maxPhotoSize*(currentFilteredVideoFrame.size.width/currentFilteredVideoFrame.size.height), _maxPhotoSize)];
            }
        }
       
        if (MIN(currentFilteredVideoFrame.size.width, currentFilteredVideoFrame.size.height) < _minPhotoSize) {
            [self showMinPhotoSizeAlert];
            return;
        }


        NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                              UIImageJPEGRepresentation(currentFilteredVideoFrame, self.outputJPEGQuality), @"data", nil];
        
        if (currentFilteredVideoFrame) {
            [info setValue:[NSNumber numberWithFloat:currentFilteredVideoFrame.size.width] forKey:@"width"];
            [info setValue:[NSNumber numberWithFloat:currentFilteredVideoFrame.size.height] forKey:@"height"];
        }
        if (selectedFilter != 0) {
            [info setValue: [NSString stringWithFormat:@"filter%i", selectedFilter] forKey:@"filter"];
        }
        if (photoSourceType == PhotoSourceTypeCamera) {
            if (stillCamera.inputCamera) {
                if (stillCamera.inputCamera.position == AVCaptureDevicePositionFront) {
                    [info setValue:@"frontCamera" forKey:@"source"];
                }else if (stillCamera.inputCamera.position == AVCaptureDevicePositionBack){
                    [info setValue:@"backCamera" forKey:@"source"];
                }
            }
        }else{
            [info setValue:@"cameraRoll" forKey:@"source"];
        }
        [self.delegate dlcImagePickerController:self didFinishPickingMediaWithInfo:info];
    }
}

-(void)showMinPhotoSizeAlert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attenzione" message:@"Le dimensioni dell'immagine sono inferiori a quelle minime consentite. Selezionare un'altra immagine." delegate:nil cancelButtonTitle:@"Chiudi" otherButtonTitles:nil,nil];
    [alert show];
}

-(IBAction) retakePhoto:(UIButton *)button {
    [self.retakeButton setHidden:YES];
    [self.libraryToggleButton setHidden:NO];
    staticPicture = nil;
    staticPictureOriginalOrientation = UIImageOrientationUp;
    isStatic = NO;
    [self removeAllTargets];
    [stillCamera startCameraCapture];
    [self.cameraToggleButton setEnabled:YES];
    [self.cameraToggleButton setHidden:NO];
    
    if([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]
       && stillCamera
       && [stillCamera.inputCamera hasTorch]) {
        [self.flashToggleButton setEnabled:YES];
        [self.flashToggleButton setHidden:NO];
        
    }
    
    [self.photoCaptureButton setImage:[UIImage imageNamed:@"camera-button"] forState:UIControlStateNormal];
    [self.photoCaptureButton setTitle:nil forState:UIControlStateNormal];
    
    if ([self.filtersToggleButton isSelected]) {
        [self hideFilters];
    }
    if (noFilterButton) {
        [self selectFilter:noFilterButton];
    }
    //selectedFilter = 0;
    //[self setFilter:selectedFilter];
    [self prepareFilter];
}

-(IBAction) cancel:(id)sender {
    [self.delegate dlcImagePickerControllerDidCancel:self];
}

-(IBAction) handlePan:(UIGestureRecognizer *) sender {
    if (hasBlur) {
        CGPoint tapPoint = [sender locationInView:imageView];
        GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            [self showBlurOverlay:YES];
            [gpu setBlurRadiusInPixels:0.0f];
            if (isStatic) {
                [staticPicture processImage];
            }
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            [gpu setBlurRadiusInPixels:0.0f];
            [self.blurOverlayView setCircleCenter:tapPoint];
            [gpu setExcludeCirclePoint:CGPointMake(tapPoint.x/320.0f, tapPoint.y/320.0f)];
        }
        
        if([sender state] == UIGestureRecognizerStateEnded){
            [gpu setBlurRadiusInPixels:kStaticBlurSize];
            [self showBlurOverlay:NO];
            if (isStatic) {
                [staticPicture processImage];
            }
        }
    }
}

- (IBAction) handleTapToFocus:(UITapGestureRecognizer *)tgr{
	if (!isStatic && tgr.state == UIGestureRecognizerStateRecognized) {
		CGPoint location = [tgr locationInView:self.imageView];
		AVCaptureDevice *device = stillCamera.inputCamera;
		CGPoint pointOfInterest = CGPointMake(.5f, .5f);
		CGSize frameSize = [[self imageView] frame].size;
		if ([stillCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
		}
		pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
		if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                self.focusView.center = [tgr locationInView:self.view];
                self.focusView.alpha = 1;
                
                [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
                    self.focusView.alpha = 0;
                } completion:nil];
                
                [device unlockForConfiguration];
			} else {
                NSLog(@"ERROR = %@", error);
			}
		}
	}
}

-(IBAction) handlePinch:(UIPinchGestureRecognizer *) sender {
    if (hasBlur) {
        CGPoint midpoint = [sender locationInView:imageView];
        GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            [self showBlurOverlay:YES];
            [gpu setBlurRadiusInPixels:0.0f];
            if (isStatic) {
                [staticPicture processImage];
            }
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            [gpu setBlurRadiusInPixels:0.0f];
            [gpu setExcludeCirclePoint:CGPointMake(midpoint.x/320.0f, midpoint.y/320.0f)];
            self.blurOverlayView.circleCenter = CGPointMake(midpoint.x, midpoint.y);
            CGFloat radius = MAX(MIN(sender.scale*[gpu excludeCircleRadius], 0.6f), 0.15f);
            self.blurOverlayView.radius = radius*320.f;
            [gpu setExcludeCircleRadius:radius];
            sender.scale = 1.0f;
        }
        
        if ([sender state] == UIGestureRecognizerStateEnded) {
            [gpu setBlurRadiusInPixels:kStaticBlurSize];
            [self showBlurOverlay:NO];
            if (isStatic) {
                [staticPicture processImage];
            }
        }
    }
}

-(void) showFilters {
    [self.filtersToggleButton setSelected:YES];
    self.filtersToggleButton.enabled = NO;
    CGRect imageRect = self.imageView.frame;
    imageRect.origin.y -= 34;
    CGRect sliderScrollFrame = self.filterScrollView.frame;
    sliderScrollFrame.origin.y -= self.filterScrollView.frame.size.height;
    CGRect sliderScrollFrameBackground = self.filtersBackgroundImageView.frame;
    sliderScrollFrameBackground.origin.y -=
    self.filtersBackgroundImageView.frame.size.height-3;
    
    self.filterScrollView.hidden = NO;
    self.filtersBackgroundImageView.hidden = YES;
    [UIView animateWithDuration:0.10
                          delay:0.05
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.imageView.frame = imageRect;
                         self.filterScrollView.frame = sliderScrollFrame;
                         self.filtersBackgroundImageView.frame = sliderScrollFrameBackground;
                     } 
                     completion:^(BOOL finished){
                         self.filtersToggleButton.enabled = YES;
                     }];
}

-(void) hideFilters {
    [self.filtersToggleButton setSelected:NO];
    CGRect imageRect = self.imageView.frame;
    imageRect.origin.y += 34;
    CGRect sliderScrollFrame = self.filterScrollView.frame;
    sliderScrollFrame.origin.y += self.filterScrollView.frame.size.height;
    
    CGRect sliderScrollFrameBackground = self.filtersBackgroundImageView.frame;
    sliderScrollFrameBackground.origin.y += self.filtersBackgroundImageView.frame.size.height-3;
    
    [UIView animateWithDuration:0.10
                          delay:0.05
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.imageView.frame = imageRect;
                         self.filterScrollView.frame = sliderScrollFrame;
                         self.filtersBackgroundImageView.frame = sliderScrollFrameBackground;
                     } 
                     completion:^(BOOL finished){
                         
                         self.filtersToggleButton.enabled = YES;
                         self.filterScrollView.hidden = YES;
                         self.filtersBackgroundImageView.hidden = YES;
                     }];
}

-(IBAction) toggleFilters:(UIButton *)sender {
    sender.enabled = NO;
    if (sender.selected){
        [self hideFilters];
    } else {
        [self showFilters];
    }
    
}

-(void) showBlurOverlay:(BOOL)show{
    if(show){
        [UIView animateWithDuration:0.2 delay:0 options:0 animations:^{
            self.blurOverlayView.alpha = 0.6;
        } completion:^(BOOL finished) {
            
        }];
    }else{
        [UIView animateWithDuration:0.35 delay:0.2 options:0 animations:^{
            self.blurOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    }
}


-(void) flashBlurOverlay {
    [UIView animateWithDuration:0.2 delay:0 options:0 animations:^{
        self.blurOverlayView.alpha = 0.6;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.35 delay:0.2 options:0 animations:^{
            self.blurOverlayView.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
    }];
}

-(void) dealloc {
    [self removeAllTargets];
    stillCamera = nil;
    cropFilter = nil;
    filter = nil;
    blurFilter = nil;
    staticPicture = nil;
    self.blurOverlayView = nil;
    self.focusView = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [stillCamera stopCameraCapture];
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (originalImage.size.width < _minPhotoSize || originalImage.size.height < _minPhotoSize) {
        [self showMinPhotoSizeAlert];
        [self imagePickerControllerDidCancel:picker];
        return;
    }

    UIImage* outputImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (outputImage == nil) {
        outputImage = originalImage;
    }
    
    CGFloat shortSide = outputImage.size.width <= outputImage.size.height ? outputImage.size.width : outputImage.size.height;
    outputImage = [outputImage cropToSize:CGSizeMake(shortSide, shortSide) usingMode:NYXCropModeCenter];

    
    if (outputImage) {
        staticPicture = [[GPUImagePicture alloc] initWithImage:outputImage smoothlyScaleOutput:YES];
        staticPictureOriginalOrientation = outputImage.imageOrientation;
        photoSourceType = PhotoSourceTypeCameraRoll;
        isStatic = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.cameraToggleButton setHidden:YES];
        [self.flashToggleButton setHidden:YES];
        [self prepareStaticFilter];
        [self.photoCaptureButton setHidden:NO];
        [self.photoCaptureButton setTitle:@"OK" forState:UIControlStateNormal];
        [self.photoCaptureButton setImage:nil forState:UIControlStateNormal];
        [self.photoCaptureButton setEnabled:YES];
        if(![self.filtersToggleButton isSelected]){
            [self showFilters];
        }
   }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (!isStatic) {
        [self retakePhoto:nil];
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#endif

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)updateLastPhotoThumbnail{
    NSString *imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"camera_roll_thumb.png"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        [libraryToggleButton setImage:[UIImage imageWithContentsOfFile:imagePath] forState:UIControlStateNormal];
        [libraryToggleButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
    }else{
        [libraryToggleButton setImage:nil forState:UIControlStateNormal];
    }
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                     usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                         if (nil != group) {
                                             // be sure to filter the group so you only get photos
                                             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                                             
                                             if (group.numberOfAssets > 0) {
                                                 [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1]
                                                                         options:0
                                                                      usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                                                          if (nil != result) {
                                                                              ALAssetRepresentation *repr = [result defaultRepresentation];
                                                                              // this is the most recent saved photo
                                                                              UIImage *img = [UIImage imageWithCGImage:[repr fullScreenImage]];
                                                                              // we only need the first (most recent) photo -- stop the enumeration
                                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                                  [libraryToggleButton setImage:img forState:UIControlStateNormal];
                                                                                  [libraryToggleButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
                                                                              });
                                                                              NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithCGImage:img.CGImage], 1.0);
                                                                              NSString *writePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"camera_roll_thumb.png"];
                                                                              if (![imageData writeToFile:writePath atomically:YES]) {
                                                                                  // failure
                                                                                  NSLog(@"image save failed to path %@", writePath);
                                                                              } else {
                                                                                  // success.
                                                                              }
                                                                              *stop = YES;
                                                                          }
                                                                      }];
                                             }
                                         }
                                         
                                         *stop = NO;
                                     } failureBlock:^(NSError *error) {
                                         NSLog(@"error: %@", error);
                                     }];
    });
    
}


@end
