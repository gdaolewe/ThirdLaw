//
//  HistoryTracker.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/18/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "HistoryTracker.h"

@implementation HistoryTracker

static int _historyIndex;

+(int) historyIndex {
    return _historyIndex;
}

+(void)setHistoryIndex:(int)index {
    _historyIndex = index;
}

@end
