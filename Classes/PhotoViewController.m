//
//  PhotoViewController.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/18/12.
//  Copyright (c) 2012 Backspaces Inc. All rights reserved.
//

#import "PhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Categories.h"

@interface PhotoViewController ()

@end

@implementation PhotoViewController

@synthesize showPickerButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView 
{
	CGRect mainScreenFrame = [[UIScreen mainScreen] bounds];
	UIView *primaryView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
    
    showPickerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    showPickerButton.frame = CGRectMake(round(mainScreenFrame.size.width / 2.0 - 150.0 / 2.0), mainScreenFrame.size.height - 90.0, 150.0, 40.0);
    [showPickerButton setTitle:@"Show picker" forState:UIControlStateNormal];
	showPickerButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [showPickerButton addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [showPickerButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    [primaryView addSubview:showPickerButton];
    
	self.view = primaryView;	
}

-(void) takePhoto:(id)sender{
    DLCImagePickerController *picker = [[DLCImagePickerController alloc] init];
    picker.delegate = self;
    picker.filtersToggleEnabled = NO;
    picker.blurToggleEnabled = NO;
    
    [self presentModalViewController:picker animated:YES];
}


-(void) imagePickerControllerDidCancel:(DLCImagePickerController *)picker{
    [self dismissModalViewControllerAnimated:YES];
}

-(void) imagePickerController:(DLCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    [self dismissModalViewControllerAnimated:YES];
    
    if (info) {
        //Write to Library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        UIImage *image = [UIImage imageWithData:[info objectForKey:@"data"]];
        UIImage *image120 = [image resizedImageToSize:CGSizeMake(120, 120)];
        UIImage *image60 = [image resizedImageToSize:CGSizeMake(60, 60)];
        
        /*[library writeImageToSavedPhotosAlbum:image60.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];
        
        [library writeImageToSavedPhotosAlbum:image120.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];*/

        
        /*[library writeImageDataToSavedPhotosAlbum:[info objectForKey:@"data"] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
         {
             if (error) {
                 NSLog(@"ERROR: the image failed to be written");
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
             }
         }];*/
        
        //Write to path
        NSData *imageData = [info objectForKey:@"data"];
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [[searchPaths lastObject] stringByAppendingPathComponent:@"image.png"];

        [imageData writeToFile:documentPath atomically:YES];
    }
}

-(void) viewDidUnload {
    [super viewDidUnload];
    showPickerButton = nil;
}
@end
