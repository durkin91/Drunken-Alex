//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Nikki Durkin on 10/9/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Penguin.h"

static const float MIN_SPEED = 7.f;

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    Penguin *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    CCAction *_followPenguin;
    int sealExplosionNumber;
}

//is called when CCB file has completed loading
-(void)didLoadFromCCB {
    
    _physicsNode.collisionDelegate = self;
    
    self.userInteractionEnabled = TRUE;
    
    sealExplosionNumber = 0;
    
    CCNode *level = [CCBReader load:@"Level1"];
    [_levelNode addChild:level];
    
    //visualize physics bodies and objects
    //_physicsNode.debugDraw = TRUE;
    
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
}

//called on every touch in this scene
-(void)touchBegan:(CCTouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    //start catapult dragging when a touch inside of the catapult arm occurs
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        //create the penguin and initially position it on the scoop. (34,138) is the position of the node space of the _catapultArm. Transform the world psoition to the node space to which the penguin will be ad (_physicsNode). Add it to the physics world and deisable rotation of the penguin.
        _currentPenguin = (Penguin *)[CCBReader load:@"Penguin"];
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        [_physicsNode addChild:_currentPenguin];
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        //create a joint to keep the penguin fixed to the scoop until the catapult is released
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
        
        //move the mouseJointNode to the touch position
        _mouseJointNode.position = touchLocation;
        
        //setup a spring joint between the mouseJointNode and the catapultArm
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0,0) anchorB:ccp(34,138) restLength:0.f stiffness:3000.f damping:150.f];
    }
}

-(void)releaseCatapult
{
    if (_mouseJoint != nil) {
        //releases the joint and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        //released the joint and lets the penguin fly with rotation
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        //follow the flying penguin
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
        
        _currentPenguin.launched = TRUE;
    }
}

-(void)touchEnded:(CCTouch *)touch withEvent:(UIEvent *)event
{
    //when user releases their finger, release the catapult
    [self releaseCatapult];
}

-(void)touchCancelled:(CCTouch *)touch withEvent:(UIEvent *)event
{
    //when user drags her finder off the screen or onto something else, release the catapult
    [self releaseCatapult];
}

-(void)touchMoved:(CCTouch *)touch withEvent:(UIEvent *)event
{
    //whenever touches move, update the position of the mouseJointNode to the touch position
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

-(void)launchPenguin
{
    //loads the Penguin.ccb and positions the penguin at the bowl of the catapult.
    CCNode *penguin = [CCBReader load:@"Penguin"];
    penguin.position = ccpAdd(_catapultArm.position, ccp(16,50));
    
    // add penguin to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:penguin];
    
    //manually create and apply a force to launch the penguin
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
    
    //ensure followed object is visible when starting
    self.position = ccp(0,0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)node
{
    float energy = [pair totalKineticEnergy];
    
    //if energy is large enough, remove the seal
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        } key:nodeA];
    }
}

-(void)sealRemoved:(CCSprite *)seal {
    
    CCTexture *texture = [CCTexture textureWithFile:@"janeBlasted.png"];
    
    seal.texture = texture;

//    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
//    explosion.autoRemoveOnFinish = TRUE;
//    explosion.position = seal.position;
//    [seal.parent addChild:explosion];
    
    sealExplosionNumber = sealExplosionNumber + 1;
    
//    [seal removeFromParent];
}

-(void)update:(CCTime)delta
{
    if (_currentPenguin.launched) {
    
        //if speed is below minimum speed, assume this attempt is over
        if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED) {
            [self nextAttempt];
            return;
        }
    
        int xMin = _currentPenguin.boundingBox.origin.x;
    
        if (xMin < self.boundingBox.origin.x) {
            [self nextAttempt];
            return;
        }
    
        int xMax = xMin + _currentPenguin.boundingBox.size.width;
    
        if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width)) {
            [self nextAttempt];
            return;
        }
    }
}

-(void)nextAttempt
{
    _currentPenguin = nil;
    [_contentNode stopAction:_followPenguin];
    
    if (sealExplosionNumber >= 11) {
        [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"MerryChristmas"]];
    }
    
    else {
        CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration:1.f position:ccp(0,0)];
        [_contentNode runAction:actionMoveTo];
    }
}


-(void)retry
{
    //reload this level
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
    sealExplosionNumber = 0;
}

@end
