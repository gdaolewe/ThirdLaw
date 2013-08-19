//
//  SegueNoAnimation.m
//  TVTropes
//
//  Created by George Daole-Wellman on 11/10/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import "SegueNoAnimation.h"

@implementation SegueNoAnimation

-(void) perform {
    [[self sourceViewController] presentModalViewController:[self destinationViewController] animated:NO];
}

@end
