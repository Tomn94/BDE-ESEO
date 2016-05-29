//
//  GameScene.h
//  ESEOmega
//
//  Created by Thomas Naudet on 05/08/2015.
//  Copyright © 2015 Thomas Naudet

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

@import SpriteKit;
@import CoreMotion;
@import AudioToolbox;
#import "LoseScreen.h"

#define SHIP_MOVEFACT    55.0
#define MISSILES_SPEED   0.8
#define MISSILES_DELAY   0.18
#define BOMBS_SPAWNTIME  0.5
#define BOMB_SHOWTIME    2.1
#define BONUS_SHOWTIME   3.0
#define BONUS_MINSCORE   15
#define BONUS_SPAWNTIME  8

#define LVL2_MINSCORE    40
#define LVL2_PROBRANGE   1000
#define BOMB_LVL2_MAXHIT 4

#define START_DELAY      2.
#define MAX_LIFE         8

#define SCENE_CATEGORY   0x1
#define SHIP_CATEGORY    0x2
#define MISSILE_CATEGORY 0x4
#define BOMB_CATEGORY    0x8
#define BONUS_CATEGORY   0x16

@interface GameScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) SKSpriteNode *plane;
@property (strong) CMMotionManager *motionManager;
@property (strong) NSMutableArray *contactQueue;
@property NSTimeInterval timeOfLastSpawn;
@property NSTimeInterval timeOfLastBonus;
@property NSTimeInterval timeOfLastTouch;
@property NSTimeInterval timeStart;
@property (strong, nonatomic) SKLabelNode *scoreHUD;
@property NSUInteger score;
@property (strong, nonatomic) NSArray *viesHUD;
@property NSInteger vies;
@property (strong, nonatomic) SKSpriteNode *back;
@property (strong, nonatomic) SKSpriteNode *back2;
@property BOOL isTouching;
@property BOOL bonusVisible;

- (void) lancerMissile;
- (void) dropBomb:(int)level;
- (void) matlabInDaPlace;
- (void) updateScoreBy:(NSInteger)diff;
- (void) updateVieBy:(NSInteger)diff;
- (void) updateBackground;

@end
