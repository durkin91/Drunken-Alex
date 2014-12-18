//
//  WaitingPenguin.m
//  PeevedPenguins
//
//  Created by Nikki Durkin on 10/9/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "WaitingPenguin.h"

@implementation WaitingPenguin

-(void)didLoadFromCCB
{
    //generate a random number between 0 and 2, then call method to start animation at random delay
    float delay = (arc4random() % 2000) / 1000.f;
    [self performSelector:@selector(startBlinkAndJump) withObject:nil afterDelay:delay];
}

-(void)startBlinkAndJump
{
    //the animation manager of each node is stored in the 'animationManager' property.
    CCAnimationManager *animationManager = self.animationManager;
    [animationManager runAnimationsForSequenceNamed:@"BlinkAndJump"];
}

@end
