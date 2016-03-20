//
//  LoseScreen.m
//  ESEOmega
//
//  Created by Tomn on 06/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

#import "LoseScreen.h"

@implementation LoseScreen

- (nonnull instancetype) initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        // SCENE
        self.scaleMode = SKSceneScaleModeAspectFill;
        
        // BACK
        SKSpriteNode *back = [SKSpriteNode spriteNodeWithImageNamed:@"sky"];
        back.zPosition = -1;
        back.size = self.size;
        back.position = CGPointMake(self.size.width / 2., self.size.height / 2.);
        [self addChild:back];
        self.backgroundColor = [SKColor colorWithRed:30/255. green:60/255. blue:130/255. alpha:1];
        
        CGFloat dec = self.size.height / 6.7;
        
        // TITLE
        SKLabelNode *title = [[SKLabelNode alloc] initWithFontNamed:@"Perfect DOS VGA 437"];
        title.text = @"**** SCORES ****";
        title.fontSize = 32;
        title.position = CGPointMake(self.frame.size.width / 2., self.frame.size.height - dec);
        [self addChild:title];
        
        // 10 1ERS SCORES
        NSMutableArray *t_scores = [NSMutableArray array];
        for (NSInteger i = 0 ; i < MAX_SCORES ; ++i)
        {
            SKLabelNode *score = [[SKLabelNode alloc] initWithFontNamed:@"Perfect DOS VGA 437"];
            if (i == 0)
                score.text = [NSString stringWithFormat:@"%02d  -pas-  connecte!", (int)i + 1];
            else
                score.text = [NSString stringWithFormat:@"%02d  -----  ---------", (int)i + 1];
            score.fontColor = [SKColor colorWithWhite:0.75 alpha:1.0];
            score.fontSize = 25;
            score.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            score.position = CGPointMake((self.frame.size.width - score.frame.size.width) / 2.,
                                          self.frame.size.height - dec - 50 - (i * (score.frame.size.height + 6)));
            [self addChild:score];
            [t_scores addObject:score];
        }
        // SI EN DEHORS
        SKLabelNode *score = [[SKLabelNode alloc] initWithFontNamed:@"Perfect DOS VGA 437"];
        score.text = [NSString stringWithFormat:@"%02d  -----  ---------", 42];
        score.fontSize = 25;
        score.position = CGPointMake(self.frame.size.width / 2.,
                                     self.frame.size.height - dec - 70 - (MAX_SCORES * (score.frame.size.height + 6)));
        score.hidden = YES;
        [self addChild:score];
        [t_scores addObject:score];
        _scoresHUD = [NSArray arrayWithArray:t_scores];
        
        // BOUTONS
        CGFloat posY = MIN(self.frame.size.height - dec - 120 - (MAX_SCORES * (score.frame.size.height + 6)), self.size.height / 4.);
        SKSpriteNode *btnRetry = [SKSpriteNode spriteNodeWithImageNamed:@"btnRetry"];
        btnRetry.name = @"btnRetry";
        btnRetry.zPosition = 2;
        btnRetry.scale = 0.3;
        btnRetry.position = CGPointMake(self.size.width / 2. + 60, posY);
        [self addChild:btnRetry];
        
        SKSpriteNode *btnQuit = [SKSpriteNode spriteNodeWithImageNamed:@"btnQuit"];
        btnQuit.name = @"btnQuit";
        btnQuit.zPosition = 2;
        btnQuit.scale = 0.3;
        btnQuit.position = CGPointMake(self.size.width / 2. - 60, posY);
        [self addChild:btnQuit];
    }
    return self;
}

- (void) touchesEnded:(nonnull NSSet *)touches
            withEvent:(nullable UIEvent *)event
{
    CGPoint location = [[touches anyObject] locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if ([node.name isEqualToString:@"btnRetry"])
    {
        GameScene *scene = [GameScene sceneWithSize:self.frame.size];
        SKTransition *reveal = [SKTransition crossFadeWithDuration:1.0];
        [self.view presentScene:scene transition:reveal];
    }
    else if ([node.name isEqualToString:@"btnQuit"])
        [[NSNotificationCenter defaultCenter] postNotificationName:@"gameover" object:nil];
}

- (void) sendScore:(NSUInteger)nvScore
{
    _score = nvScore;
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:URL_GP];
    NSString *client = [Data encoderPourURL:[JNKeychain loadValueForKey:@"login"]];
    NSString *pass   = [Data encoderPourURL:[JNKeychain loadValueForKey:@"passw"]];
    NSString *score  = [NSString stringWithFormat:@"%d", (int)_score];
    NSString *body   = [NSString stringWithFormat:@"score=%@&client=%@&password=%@&hash=%@",
                        score, client, pass,
                        [Data encoderPourURL:[Data hashed_string:[[[@"**** SCORES ****" stringByAppendingString:client] stringByAppendingString:score] stringByAppendingString:pass]]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *r, NSError *error)
                                      {
                                          NSDictionary *JSON = nil;
                                          if (error == nil && data != nil)
                                          {
                                              JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                                     options:kNilOptions
                                                                                       error:nil];
                                              if ([JSON[@"status"] intValue] == 1)
                                              {
                                                  JSON = JSON[@"data"];
                                                  
                                                  NSUInteger c = [JSON[@"best"] count];
                                                  for (NSInteger i = 0 ; i < c ; ++i)
                                                  {
                                                      NSDictionary *infos = JSON[@"best"][i];
                                                      SKLabelNode *score = _scoresHUD[i];
                                                      score.text = [NSString stringWithFormat:@"%02d  %05d  %@",
                                                                    (int)i + 1, [infos[@"score"] intValue], infos[@"login"]];
                                                      if ([infos[@"login"] isEqualToString:[JNKeychain loadValueForKey:@"login"]])
                                                          score.fontColor = [SKColor whiteColor];
                                                  }
                                                  if ([JSON[@"rank"] intValue] > 10)
                                                  {
                                                      SKLabelNode *score = _scoresHUD[MAX_SCORES];
                                                      score.text = [NSString stringWithFormat:@"%02d  %05d  %@",
                                                                    [JSON[@"rank"] intValue], [JSON[@"bscore"] intValue], [JNKeychain loadValueForKey:@"login"]];
                                                      score.fontColor = [SKColor whiteColor];
                                                      score.hidden = NO;
                                                  }
                                              }
                                              else
                                              {
                                                  SKLabelNode *score = _scoresHUD[0];
                                                  if ([JSON[@"status"] intValue] == -2)
                                                      score.text = @"01  erreur mot-passe";
                                                  else
                                                      score.text = @"01  erreur -serveur-";
                                              }
                                          }
                                      }];
    [dataTask resume];
}

@end
