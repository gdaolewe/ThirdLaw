//
//  UserDefaultsHelper.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/25/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDefaultsHelper : NSObject

#define USER_PREF_EXTERNAL_URL				@"ExternalURL"
#define USER_PREF_FULLSCREEN				@"Fullscreen"
#define USER_PREF_HISTORY_INDEX				@"HistoryIndex"
#define USER_PREF_ROTATION_LOCKED			@"RotationLocked"
#define USER_PREF_ROTATION_ORIENTATION		@"RotationOrientation"
#define USER_PREF_SAVED_PAGES_STARTING_TAB	@"SavedPagesStartingTab"
#define USER_PREF_SEARCH_STRING				@"SearchString"
#define USER_PREF_START_VIEW				@"StartView"

typedef enum {
	UserPrefStartViewPage,
	USerPrefStartViewExternal
}UserPrefStartView;

@end
