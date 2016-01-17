//
//  ClubsSelectionDelegate.h
//  ESEOmega
//
//  Created by Thomas Naudet on 22/07/2015.
//  Copyright © 2015 Thomas Naudet. All rights reserved.
//

@import Foundation;

@protocol ClubsSelectionDelegate <NSObject>

@required
- (void) selectedClub:(nonnull NSDictionary *)infos;

@end
