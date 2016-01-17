//
//  EventAlertView.m
//  ESEOmega
//
//  Created by Tomn on 18/09/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

#import "EventAlertView.h"

@implementation EventAlertView

@end


@implementation EventAlertViewController

- (void) set3DBoutons:(NSArray<id<UIPreviewActionItem>> *)items
{
    boutons = items;
}

- (NSArray<id<UIPreviewActionItem>> *) previewActionItems
{
    return [NSArray arrayWithArray:boutons];
}

@end