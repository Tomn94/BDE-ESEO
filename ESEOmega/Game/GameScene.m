//
//  GameScene.m
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

#import "GameScene.h"

@implementation GameScene

- (nonnull instancetype) initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        // SCENE
        self.scaleMode = SKSceneScaleModeAspectFill;
        
        self.contactQueue = [NSMutableArray array];
        self.physicsWorld.contactDelegate = self;
        
        // BACK
        _back = [SKSpriteNode spriteNodeWithImageNamed:@"sky"];
        _back.zPosition = -1;
        _back.size = self.size;
        _back.position = CGPointMake(self.size.width / 2., self.size.height / 2.);
        [self addChild:_back];
        _back2 = [SKSpriteNode spriteNodeWithImageNamed:@"sky"];
        _back2.zPosition = -1;
        _back2.size = self.size;
        _back2.position = CGPointMake(self.size.width / 2., self.size.height * 3 / 2.);
        [self addChild:_back2];
        self.backgroundColor = [SKColor colorWithRed:30/255. green:60/255. blue:130/255. alpha:1];
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody.categoryBitMask = SCENE_CATEGORY;
        
        _timeStart = 0;
        _isTouching = NO;
        
        // AVION
        _plane = [SKSpriteNode spriteNodeWithImageNamed:@"spaceship"];
        _plane.name = @"plane";
        _plane.scale = 0.2;
        _plane.zPosition = 2;
        _plane.position = CGPointMake(size.width / 2, 15 + _plane.size.height / 2);
        
        _plane.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_plane.frame.size.width / 2. - 5.];
        _plane.physicsBody.dynamic = YES;
        _plane.physicsBody.affectedByGravity = NO;
        _plane.physicsBody.mass = 0.02;
        _plane.physicsBody.categoryBitMask = SHIP_CATEGORY;
        _plane.physicsBody.contactTestBitMask = BOMB_CATEGORY | BONUS_CATEGORY;
        _plane.physicsBody.collisionBitMask = SCENE_CATEGORY;
        [self addChild:_plane];
        
        self.motionManager = [CMMotionManager new];
        [self.motionManager startAccelerometerUpdates];
        
        // HUD
        _score = 0;
        _scoreHUD = [[SKLabelNode alloc] initWithFontNamed:@"Karmatic Arcade"];
        _scoreHUD.text = @"00000";
        _scoreHUD.zPosition = 7;
        _scoreHUD.fontSize = 42;
        _scoreHUD.position = CGPointMake(8, self.frame.size.height - _scoreHUD.frame.size.height);
        _scoreHUD.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        [self addChild:_scoreHUD];
        
        _vies = 3;
        NSMutableArray *t_vies = [NSMutableArray array];
        for (NSInteger i = 0 ; i < MAX_LIFE ; ++i)
        {
            SKSpriteNode *vie = [SKSpriteNode spriteNodeWithImageNamed:@"vie"];
            vie.scale = 0.04;
            vie.zPosition = 5;
            vie.position = CGPointMake(25 + i * (vie.size.width + 5), self.frame.size.height - vie.frame.size.height - _scoreHUD.frame.size.height - 10);
            vie.alpha = (_vies > i);
            [self addChild:vie];
            [t_vies addObject:vie];
        }
        _viesHUD = [NSArray arrayWithArray:t_vies];
    }
    return self;
}

#pragma mark - Événements

- (void) update:(NSTimeInterval)currentTime
{
    if (_vies < 0)
        return;
    
    [self processContactsForUpdate:currentTime];
    [self processUserMotionForUpdate:currentTime];
    [self updateBackground];
    
    if (_timeStart == 0)
        _timeStart = currentTime;
    if (currentTime - _timeStart > START_DELAY && _timeStart != currentTime)
    {
        // BONUS
        if (_score >= BONUS_MINSCORE && !_bonusVisible &&
            currentTime - _timeOfLastBonus > BONUS_SPAWNTIME)
        {
            [self matlabInDaPlace];
            _timeOfLastBonus = currentTime;
        }
        
        // BOMBE
        if (currentTime - _timeOfLastSpawn > BOMBS_SPAWNTIME)
        {
            int lvl = 0;
            if (_score >= LVL2_MINSCORE && arc4random_uniform(LVL2_PROBRANGE) < _score)
                lvl = 1;
            [self dropBomb:lvl];
            _timeOfLastSpawn = currentTime;
        }
    }
    
    if (_isTouching && [NSDate timeIntervalSinceReferenceDate] - _timeOfLastTouch > MISSILES_DELAY)
        [self lancerMissile];
}

- (void) touchesBegan:(nonnull NSSet *)touches
            withEvent:(nullable UIEvent *)event
{
    _isTouching = YES;
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches
            withEvent:(UIEvent *)event
{
    _isTouching = NO;
}

- (void) processUserMotionForUpdate:(NSTimeInterval)currentTime
{
    CMAccelerometerData *data = self.motionManager.accelerometerData;
    if (fabs(data.acceleration.x) > 0.2)
        [_plane.physicsBody applyForce:CGVectorMake(SHIP_MOVEFACT * data.acceleration.x, 0)];
}

#pragma mark - Actions

- (void) lancerMissile
{
    _timeOfLastTouch = [NSDate timeIntervalSinceReferenceDate];
    
    SKSpriteNode *missile = [SKSpriteNode spriteNodeWithImageNamed:@"missile"];
    missile.name = @"missile";
    missile.scale = 0.1;
    missile.zPosition = 0;
    missile.position = _plane.position;
    
    missile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:missile.frame.size];
    missile.physicsBody.dynamic = YES;
    missile.physicsBody.affectedByGravity = NO;
    missile.physicsBody.categoryBitMask = MISSILE_CATEGORY;
    missile.physicsBody.contactTestBitMask = 0;
    missile.physicsBody.collisionBitMask = 0;
    [self addChild:missile];
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(missile.position.x, self.size.height)
                                   duration:MISSILES_SPEED];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [missile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

- (void) dropBomb:(int)level
{
    SKSpriteNode *bombe = [SKSpriteNode spriteNodeWithImageNamed:(level == 1) ? @"starpatrol" : @"bombe"];
    bombe.userData = [NSMutableDictionary dictionary];
    [bombe.userData setValue:@(level) forKey:@"level"];
    [bombe.userData setValue:@0 forKey:@"nbrHit"];
    bombe.name = @"bombe";
    bombe.scale = (level == 1) ? 0.195 : 0.165;
    bombe.zPosition = 1;
    bombe.position = CGPointMake(bombe.size.width + arc4random_uniform(self.size.width - (2 * bombe.size.width)), self.size.height);
    
    bombe.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:bombe.size.width / 2.];
    bombe.physicsBody.dynamic = NO;
    bombe.physicsBody.categoryBitMask = BOMB_CATEGORY;
    bombe.physicsBody.contactTestBitMask = MISSILE_CATEGORY;
    bombe.physicsBody.collisionBitMask = MISSILE_CATEGORY;
    [self addChild:bombe];
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(bombe.position.x, -self.size.height)
                                   duration:(level > 0) ? ((level + 2) * BOMB_SHOWTIME) : BOMB_SHOWTIME];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [bombe runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

- (void) matlabInDaPlace
{
    _bonusVisible = YES;
    SKSpriteNode *bonus = [SKSpriteNode spriteNodeWithImageNamed:@"matlab"];
    bonus.name = @"bonus";
    bonus.scale = 0.25;
    bonus.zPosition = 1;
    bonus.position = CGPointMake(bonus.size.width + arc4random_uniform(self.size.width - (2 * bonus.size.width)), self.size.height);
    
    bonus.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:bonus.size.width / 2.];
    bonus.physicsBody.dynamic = NO;
    bonus.physicsBody.categoryBitMask = BONUS_CATEGORY;
    bonus.physicsBody.contactTestBitMask = MISSILE_CATEGORY;
    bonus.physicsBody.collisionBitMask = MISSILE_CATEGORY;
    [self addChild:bonus];
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(bonus.position.x, -self.size.height)
                                   duration:BONUS_SHOWTIME];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    SKAction *actionViePartie = [SKAction runBlock:^{
        _bonusVisible = NO;
    }];
    [bonus runAction:[SKAction sequence:@[actionMove, actionMoveDone, actionViePartie]]];
}

#pragma mark - Contact delegate

- (void) didBeginContact:(SKPhysicsContact *)contact
{
    [self.contactQueue addObject:contact];
}

- (void) processContactsForUpdate:(NSTimeInterval)currentTime
{
    for (SKPhysicsContact* contact in [self.contactQueue copy])
    {
        [self handleContact:contact];
        [self.contactQueue removeObject:contact];
    }
}

- (void) handleContact:(SKPhysicsContact*)contact
{
    // Ensure you haven't already handled this contact and removed its nodes
    if (!contact.bodyA.node.parent || !contact.bodyB.node.parent)
        return;
    
    NSArray *nodeNames = @[contact.bodyA.node.name, contact.bodyB.node.name];
    
    // CRASH
    if ([nodeNames containsObject:@"plane"] && [nodeNames containsObject:@"bombe"])
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [self updateVieBy:-1];
        SKNode *plane = contact.bodyA.node;
        SKNode *bombe = contact.bodyB.node;
        if ([nodeNames indexOfObject:@"bombe"] == 0)
        {
            bombe = contact.bodyA.node;
            plane = contact.bodyB.node;
        }
        if (_vies < 0)
            [plane removeFromParent];
        [bombe removeFromParent];
    }
    // BOMBE ÉLIMINÉE
    else if ([nodeNames containsObject:@"bombe"] && [nodeNames containsObject:@"missile"])
    {
        SKNode *missile = contact.bodyA.node;
        SKNode *bombe   = contact.bodyB.node;
        if ([nodeNames indexOfObject:@"bombe"] == 0)
        {
            bombe   = contact.bodyA.node;
            missile = contact.bodyB.node;
        }
        
        
        NSInteger lvlBombe = [[bombe.userData valueForKey:@"level"] integerValue];
        NSInteger nbrHit = [[bombe.userData valueForKey:@"nbrHit"] integerValue];
        [bombe.userData setValue:@(nbrHit + 1) forKey:@"nbrHit"];
        if (nbrHit == BOMB_LVL2_MAXHIT - 1 || lvlBombe == 0)
        {
            [bombe removeFromParent];
            [self updateScoreBy:(lvlBombe == 0) ? 1 : BOMB_LVL2_MAXHIT];
        }
        [missile removeFromParent];
    }
    // BONUS
    else if ([nodeNames containsObject:@"bonus"] && [nodeNames containsObject:@"missile"])
    {
        [self updateVieBy:1];
        [contact.bodyA.node removeFromParent];
        [contact.bodyB.node removeFromParent];
    }
    else if ([nodeNames containsObject:@"plane"] && [nodeNames containsObject:@"bonus"])
    {
        [self updateVieBy:1];
        if ([nodeNames indexOfObject:@"bonus"] == 0)
            [contact.bodyA.node removeFromParent];
        else
            [contact.bodyB.node removeFromParent];
    }
}

- (void) updateScoreBy:(NSInteger)diff
{
    _score += diff;
    
    _scoreHUD.text = [NSString stringWithFormat:@"%05ld", (long)_score];
}

- (void) updateVieBy:(NSInteger)diff
{
    if (_vies == MAX_LIFE && diff > 0)
        return;
    _vies += diff;
    
    NSInteger index = 0;
    for (SKSpriteNode *vieHUD in _viesHUD)
    {
        vieHUD.alpha = (_vies > index);
        index++;
    }
    
    if (_vies == -1)
    {
        LoseScreen *scene = [LoseScreen sceneWithSize:self.view.bounds.size];
        [scene sendScore:_score];
        SKTransition *reveal = [SKTransition crossFadeWithDuration:1.0];
        [self.view presentScene:scene transition:reveal];
    }
}

- (void) updateBackground
{
    if (_back.position.y - 1 == -self.size.height / 2.)
        _back.position = CGPointMake(_back.position.x, self.size.height * 3 / 2.);
    else
        _back.position = CGPointMake(_back.position.x, _back.position.y - 1);
    
    if (_back2.position.y - 1 == -self.size.height / 2.)
        _back2.position = CGPointMake(_back2.position.x, self.size.height * 3 / 2.);
    else
        _back2.position = CGPointMake(_back2.position.x, _back2.position.y - 1);
}

@end
