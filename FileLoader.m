//
//  FileLoader.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "FileLoader.h"

@implementation FileLoader
NSString* appSupportDir;
+(void) downloadFiles {
    appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        //Create one
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            //Mark the directory as excluded from iCloud backups
            NSURL *url = [NSURL fileURLWithPath:appSupportDir];
            if (![url setResourceValue:[NSNumber numberWithBool:YES]
                                forKey:NSURLIsExcludedFromBackupKey
                                 error:&error])
            {
                NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error.localizedDescription);
            }
            else {
                NSLog(@"Yay");
            }
        }
    }
    [self downloadScriptToDir:appSupportDir];
    [self downloadCSSToDir:appSupportDir];
}

+(void) downloadScriptToDir: (NSString*) dir {
    NSURL* scriptURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/2555201/script.js"];
    NSData* scriptData = [NSData dataWithContentsOfURL:scriptURL];
    if (scriptData) {
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", dir,@"script.js"];
        [scriptData writeToFile:filePath atomically:YES];
    } else {
        NSLog(@"Error downloading script to Application Support directory.");
    }
}

+(void) downloadCSSToDir: (NSString*) dir {
    NSURL* styleURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/2555201/css_white.css"];
    NSData* styleData = [NSData dataWithContentsOfURL:styleURL];
    if (styleData) {
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", dir,@"css_white.css"];
        [styleData writeToFile:filePath atomically:YES];
    } else {
        NSLog(@"Error downloading stylesheet to Application Support directory.");
    }
}

+(NSString*) getScript {
    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDir,@"script.js"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
}
+(NSString*) getCSSPath {
    return [NSString stringWithFormat:@"%@/%@", appSupportDir,@"css_white.css"];
}

@end
