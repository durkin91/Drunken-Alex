//
//  Seal.m
//  PeevedPenguins
//
//  Created by Nikki Durkin on 10/9/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Seal.h"

@implementation Seal

-(void)didLoadFromCCB
{
    //allows us to identify when seals participate in a collision
    self.physicsBody.collisionType = @"seal";
}


@end
