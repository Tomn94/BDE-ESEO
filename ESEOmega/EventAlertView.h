//
//  EventAlertView.h
//  ESEOmega
//
//  Created by Tomn on 18/09/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;

@interface EventAlertView : UIView

@property (weak, nonatomic) IBOutlet UIView *backTitle;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *dateFinLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateFin;
@property (weak, nonatomic) IBOutlet UILabel *clubLabel;
@property (weak, nonatomic) IBOutlet UILabel *club;
@property (weak, nonatomic) IBOutlet UILabel *lieuLabel;
@property (weak, nonatomic) IBOutlet UILabel *lieu;
@property (weak, nonatomic) NSString *URL;

@end


@interface EventAlertViewController : UIViewController
{
    NSArray *boutons;
}

- (void) set3DBoutons:(NSArray<id<UIPreviewActionItem>> *) items;

@end