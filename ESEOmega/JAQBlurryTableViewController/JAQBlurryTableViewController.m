//
//  JAQViewController.m
//  MagicTableView
//
//  Created by Javier Querol on 03/01/14.
//  Copyright (c) 2014 Javier Querol. All rights reserved.
//

#import "JAQBlurryTableViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+Fit.h"

@implementation JAQBlurryTableViewController

- (void)configureBannerWithURL:(NSURL *)URL
{
    if (self.titleImageView)
        [self.titleImageView removeFromSuperview];
    if (self.blurImageView)
        [self.blurImageView removeFromSuperview];
    if (self.contentView)
        [self.contentView removeFromSuperview];
    
    self.titleImageView = [UIImageView new];
    self.titleImageView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 200);
    self.titleImageView.clipsToBounds = YES;
    self.cachedImageViewSize = self.titleImageView.frame;
    self.titleImageView.alpha = 0;
    self.titleImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.tableView addSubview:self.titleImageView];
    
    self.blurImageView = [UIImageView new];
    self.blurImageView.frame = self.titleImageView.bounds;
    self.blurImageView.clipsToBounds = YES;
    self.blurImageView.contentMode = self.titleImageView.contentMode;
    [self.tableView insertSubview:self.blurImageView belowSubview:self.titleImageView];
    
    self.contentView = [UIView new];
    self.contentView.frame = self.titleImageView.bounds;
    [self.tableView addSubview:self.contentView];
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:self.cachedImageViewSize];
    
    [self.titleImageView sd_setImageWithURL:URL
                           placeholderImage:[UIImage imageNamed:@"placeholder"]
                                  completed:^(UIImage *imageDown, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
                                  {
                                      imageDown = [imageDown jaq_adjustImageToWidth:self.view.bounds.size.width];
                                      self.blurImageView.image = [imageDown applyBlurWithRadius:12
                                                                                      tintColor:[UIColor colorWithWhite:0 alpha:0.5]
                                                                          saturationDeltaFactor:1
                                                                                      maskImage:nil];
                                  }];
    self.titleImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.blurImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self scrollViewDidScroll:self.tableView];
}

- (void)configureBannerWithImage:(UIImage *)image
{
    self.offsetBase = -64;
	[self configureBannerWithImage:image
						blurRadius:12
					 blurTintColor:[UIColor colorWithWhite:0 alpha:0.5]
				  saturationFactor:1];
}

- (void)configureBannerWithImage:(UIImage *)image
                      blurRadius:(CGFloat)blurRadius
                   blurTintColor:(UIColor *)blurColor
                saturationFactor:(CGFloat)saturarion
{
    [self configureBannerWithImage:(UIImage *)image
                        blurRadius:(CGFloat)blurRadius
                     blurTintColor:(UIColor *)blurColor
                  saturationFactor:(CGFloat)saturarion
                         maxHeight:200];
}

- (void)configureBannerWithImage:(UIImage *)image
					  blurRadius:(CGFloat)blurRadius
				   blurTintColor:(UIColor *)blurColor
				saturationFactor:(CGFloat)saturarion
                       maxHeight:(CGFloat)heightMax
{
	image = [image jaq_adjustImageToWidth:self.view.bounds.size.width];
    
    if (self.titleImageView)
        [self.titleImageView removeFromSuperview];
    if (self.blurImageView)
        [self.blurImageView removeFromSuperview];
    if (self.contentView)
        [self.contentView removeFromSuperview];
    
	self.titleImageView = [UIImageView new];
	self.titleImageView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, MIN(heightMax, image.size.height));
    self.titleImageView.clipsToBounds = YES;
	self.cachedImageViewSize = self.titleImageView.frame;
	self.titleImageView.alpha = 0;
	self.titleImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.tableView addSubview:self.titleImageView];
	
	self.blurImageView = [UIImageView new];
    self.blurImageView.frame = self.titleImageView.bounds;
    self.blurImageView.clipsToBounds = YES;
	self.blurImageView.contentMode = self.titleImageView.contentMode;
	[self.tableView insertSubview:self.blurImageView belowSubview:self.titleImageView];
	
	self.contentView = [UIView new];
	self.contentView.frame = self.titleImageView.bounds;
	[self.tableView addSubview:self.contentView];
	
	self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:self.cachedImageViewSize];
	self.titleImageView.image = image;
	self.blurImageView.image = [self.titleImageView.image applyBlurWithRadius:blurRadius
																	tintColor:blurColor
														saturationDeltaFactor:saturarion
                                                                    maskImage:nil];
    self.titleImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.blurImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self scrollViewDidScroll:self.tableView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat scrollOffset = -scrollView.contentOffset.y;
    CGFloat scrollOffset2 = scrollOffset + _offsetBase;
    CGFloat newScale = 1 + scrollOffset2 / self.cachedImageViewSize.size.height;
	self.titleImageView.alpha = (newScale-1)*2;
	self.contentView.alpha = 1-self.titleImageView.alpha;
	
    if (scrollOffset > 0) {
        self.titleImageView.frame = CGRectMake(self.view.bounds.origin.x,
											   scrollView.contentOffset.y,
											   self.cachedImageViewSize.size.width+scrollOffset,
											   self.cachedImageViewSize.size.height+scrollOffset);
		
        self.titleImageView.center = CGPointMake(self.tableView.center.x, self.titleImageView.center.y);
		self.blurImageView.frame = self.titleImageView.frame;
    }
}

@end
