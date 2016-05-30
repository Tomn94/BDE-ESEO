//
//
//  Created by Javier Querol on 03/01/14.
//  Copyright (c) 2014 Javier Querol. All rights reserved.
//

@import UIKit;
#import "../SDWebImage/UIImageView+WebCache.h"

@interface JAQBlurryTableViewController : UITableViewController
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UIImageView *blurImageView;
@property (nonatomic, assign) NSInteger offsetBase;
@property (nonatomic, assign) CGRect cachedImageViewSize;

- (void)configureBannerWithURL:(NSURL *)URL;

- (void)configureBannerWithImage:(UIImage *)image;

- (void)configureBannerWithImage:(UIImage *)image
                      blurRadius:(CGFloat)blurRadius
                   blurTintColor:(UIColor *)blurColor
                saturationFactor:(CGFloat)saturarion;

- (void)configureBannerWithImage:(UIImage *)image
                      blurRadius:(CGFloat)blurRadius
                   blurTintColor:(UIColor *)blurColor
                saturationFactor:(CGFloat)saturarion
                       maxHeight:(CGFloat)heightMax;

@end
