//
//  FileLoader.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "FileLoader.h"
#import "IndexData.h"

NSString *const DEV_HOST = @"http://192.168.1.115:3000";
NSString *_host;

@implementation FileLoader

NSString* appSupportDir;
+(void) downloadFiles {
    _host = DEV_HOST;
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
        }
    }
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.georgedw.Lampshade.LaunchFileDownload", NULL);
    dispatch_async(backgroundQueue, ^{
        [self downloadScriptToDir:appSupportDir];
        [self downloadCSSToDir:appSupportDir];
        [self downloadHomePageToDir:appSupportDir];
        [self downloadIndexPageToDir:appSupportDir];
        [[IndexData sharedIndexData] loadHTML];
    });
    
}

+(void) downloadScriptToDir: (NSString*) dir {
    NSURL* scriptURL = [NSURL URLWithString:[_host stringByAppendingPathComponent:@"script.js"]];
    NSData* scriptData = [NSData dataWithContentsOfURL:scriptURL];
    if (scriptData) {
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", dir,@"script.js"];
        [scriptData writeToFile:filePath atomically:YES];
    } else {
        NSLog(@"Error downloading script to Application Support directory.");
    }
}

+(void) downloadCSSToDir: (NSString*) dir {
    NSURL* styleURL = [NSURL URLWithString:[_host stringByAppendingPathComponent:@"css_white.css"]];
    NSData* styleData = [NSData dataWithContentsOfURL:styleURL];
    if (styleData) {
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", dir,@"css_white.css"];
        [styleData writeToFile:filePath atomically:YES];
    } else {
        NSLog(@"Error downloading stylesheet to Application Support directory.");
    }
}

+(void) downloadHomePageToDir:(NSString*)dir {
    NSURL *homeURL = [NSURL URLWithString:@"http://tvtropes.org/pmwiki/pmwiki.php/Main/HomePage"];
    NSData *homePageData = [NSData dataWithContentsOfURL:homeURL];
    if (homePageData) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", dir, @"home.html"];
        [homePageData writeToFile:filePath atomically:YES];
    } else {
        NSLog(@"Error downloading home page to Application Support directory");
    }
}

+(void) downloadIndexPageToDir:(NSString*)dir {
    NSURL *indexURL = [NSURL URLWithString:@"http://tvtropes.org/pmwiki/pmwiki.php/Main/Tropes"];
    NSData *indexData = [NSData dataWithContentsOfURL:indexURL];
    if (indexData) {
        NSString* filePath = [NSString stringWithFormat:@"%@/%@", dir, @"index.html"];
        [indexData writeToFile:filePath atomically:YES];
    } else {
        NSLog(@"Error downloading index to Application Support directory");
    }
}

+(NSString*) getScript {
    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDir,@"script.js"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) {    //not in app support, getting from bundle instead
        filePath = [[NSBundle mainBundle] pathForResource:@"script" ofType:@"js"];
        NSLog(@"getting script from bundle");
        fileData = [NSData dataWithContentsOfFile:filePath];
    }
    return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
}
+(NSString*) getCSSPath {
    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDir,@"css_white.css"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) {
        filePath = [[NSBundle mainBundle] pathForResource:@"css_white" ofType:@"css"];
        NSLog(@"getting css from bundle");
        fileData = [NSData dataWithContentsOfFile:filePath];
    }
    return filePath;
}
+(NSString*) getHomePage {
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", appSupportDir, @"home.html"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) {
        filePath = [[NSBundle mainBundle] pathForResource:@"home" ofType:@"html"];
        NSLog(@"getting home page from bundle");
        fileData = [NSData dataWithContentsOfFile:filePath];
    }
    return [[NSString alloc] initWithData:fileData encoding:NSASCIIStringEncoding];
}
+(NSData*) getIndexData {
    NSString* filePath = [NSString stringWithFormat:@"%@/%@", appSupportDir, @"index.html"];
    NSData* fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) {
        filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
        NSLog(@"getting index from bundle");
        fileData = [NSData dataWithContentsOfFile:filePath];
    }
    return fileData;
}

@end
