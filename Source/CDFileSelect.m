// CDFileSelect.m
// cocoadialog
//
// Copyright (c) 2004-2017 Mark A. Stratman <mark@sporkstorms.org>, Mark Carver <mark.carver@me.com>.
// All rights reserved.
// Licensed under GPL-2.

#import "CDFileSelect.h"

@implementation CDFileSelect

- (CDOptions *) availableOptions {
    CDOptions *options = [super availableOptions];

    [options add:[CDOptionMultipleStrings       name:@"allowed-files"]];
    [options add:[CDOptionBoolean               name:@"select-directories"]];
    [options add:[CDOptionBoolean               name:@"select-only-directories"]];
    [options add:[CDOptionBoolean               name:@"no-select-directories"]];
    [options add:[CDOptionBoolean               name:@"select-multiple"]];
    [options add:[CDOptionBoolean               name:@"no-select-multiple"]];

    return options;
}

- (void) initControl {
    savePanel = [NSOpenPanel openPanel];
	NSString *file = nil;
	NSString *dir = nil;

	[self setMisc];

    NSOpenPanel *openPanel = (NSOpenPanel *)savePanel;

	// Multiple selection.
    [openPanel setAllowsMultipleSelection:option[@"select-multiple"].wasProvided];

	// Select directories.
    [openPanel setCanChooseDirectories:option[@"create-directories"].wasProvided || option[@"select-directories"].wasProvided];

    // Select only directories.
    if (option[@"select-only-directories"].wasProvided) {
		[openPanel setCanChooseDirectories:YES];
		[openPanel setCanChooseFiles:NO];
	}

    // Packages as directories.
    [openPanel setTreatsFilePackagesAsDirectories:option[@"packages-as-directories"].wasProvided];

	// set starting file (to be used later with 
	// runModal...) - doesn't work.
	if (option[@"with-file"].wasProvided) {
		file = option[@"with-file"].stringValue;
	}
	// set starting directory (to be used later with runModal...)
	if (option[@"with-directory"].wasProvided) {
		dir = option[@"with-directory"].stringValue;
	}
    
    // Check for dir or file path existance.
    NSFileManager *fm = [[NSFileManager alloc] init];
    // Directory
    if (dir != nil && ![fm fileExistsAtPath:dir]) {
        [self warning:@"Option --with-directory specifies a directory that does not exist: %@", dir, nil];
    }
    // File
    if (file != nil && ![fm fileExistsAtPath:file]) {
        [self warning:@"Option --with-file specifies a file that does not exist: %@", file, nil];
    }

    self.panel = openPanel;

    [self initPanel];
    [self initTimeout];
    
    NSInteger result;

    if (dir != nil) {
        if (file != nil) {
            dir = [dir stringByAppendingString:@"/"];
            dir = [dir stringByAppendingString:file];
        }
        NSURL * url = [[NSURL alloc] initFileURLWithPath:dir];
        openPanel.directoryURL = url;
    }
    result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSMutableArray *files = [NSMutableArray array];
        NSEnumerator *en = [openPanel.URLs objectEnumerator];
        id key;
        while (key = [en nextObject]) {
            [files addObject:[key path]];
        }
        returnValues[@"button"] = option[@"return-labels"] ? NSLocalizedString(@"OKAY", nil) : @0;
        returnValues[@"value"] = files;
    }
    else {
        exitStatus = CDExitCodeCancel;
        returnValues[@"button"] = option[@"return-labels"] ? NSLocalizedString(@"CANCEL", nil) : @1;
    }
    [super stopControl];
}

- (BOOL)isExtensionAllowed:(NSString *)filename {
    BOOL extensionAllowed = YES;
    if (extensions != nil && extensions.count) {
        NSString* extension = filename.pathExtension;
        extensionAllowed = [extensions containsObject:extension];
    }
    if (option[@"allowed-files"].wasProvided) {
        NSArray *allowedFiles = option[@"allowed-files"].arrayValue;
        if (allowedFiles != nil && allowedFiles.count) {
            if ([allowedFiles containsObject:filename.lastPathComponent]) {
                return YES;
            }
            else {
                return NO;
            }
        }
        else {
            return extensionAllowed;
        }
    }
    else {
        return extensionAllowed;
    }
}

@end