//
//  FullScreenImagePickerController.m
//  DLCImagePickerController
//
//  Created by Lorenzo Pino on 29/06/14.
//  Copyright (c) 2014 Backspaces Inc. All rights reserved.
//

#import "FullScreenImagePickerController.h"

@interface FullScreenImagePickerController ()

@end

@implementation FullScreenImagePickerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
