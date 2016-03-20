//
//  GameVC.h
//  ESEOmega
//
//  Created by Tomn on 05/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import UIKit;
@import SpriteKit;
@import AVFoundation;
#import "GameScene.h"

@interface GameVC : UIViewController
{
    SKView *gameView;
    AVAudioPlayer *audioPlayer;
}

@end
