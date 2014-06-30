//
//  FilterThumbnailView.h
//  MusicOn
//
//  Created by Lorenzo Pino on 30/05/14.
//  Copyright (c) 2014 D-still. All rights reserved.
//

#import <UIKit/UIKit.h>


#define THUMBS_PADDING 8.0

#define THUMBS_WIDTH 54.0

@interface FilterThumbnailView : UIView

-(id)initWithImage:(UIImage*)img andIndex:(NSInteger)index;
-(void)showBorder:(BOOL)showBorder;


@end
