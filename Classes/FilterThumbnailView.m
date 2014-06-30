//
//  FilterThumbnailView.m
//  MusicOn
//
//  Created by Lorenzo Pino on 30/05/14.
//  Copyright (c) 2014 D-still. All rights reserved.
//

#import "FilterThumbnailView.h"

#define SELECTED_FILTER_BORDER_WIDTH 1.0

@implementation FilterThumbnailView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithImage:(UIImage*)img andIndex:(NSInteger)index{
    self = [super initWithFrame:CGRectMake(0, 0, THUMBS_WIDTH, THUMBS_WIDTH)];
    if (self) {
        self.tag = index;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, THUMBS_WIDTH, THUMBS_WIDTH)];
        imageView.image = img;
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:imageView];
    }
    return self;
}

-(void)showBorder:(BOOL)showBorder{
    if (showBorder) {
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = SELECTED_FILTER_BORDER_WIDTH;
    }else{
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0.0;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
