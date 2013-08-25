//
//  FileLoader.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FILES_NOTIFICATION_NAME @"com.georgedw.lampshade.filesdownloaded"

@interface FileLoader : NSObject

+(void) downloadFiles;
+(NSString*) getScript;
+(NSString*) getCSSPath;
+(NSString*) getHomePage;
+(NSData*) getIndexData;

@end
