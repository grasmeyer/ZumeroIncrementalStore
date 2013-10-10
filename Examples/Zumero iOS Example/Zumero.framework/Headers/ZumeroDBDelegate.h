//
//  ZumeroDBDelegate.h
//  zumero-ios
//
//  Created by Paul Roub on 1/9/13.
//  Copyright (c) 2013 SourceGear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZumeroDBDelegate <NSObject>

- (void) syncSuccess:(NSString *)dbname;
- (void) syncFail:(NSString *)dbname err:(NSError *)err;

@optional
- (void) syncProgress:(NSString *)dbname partial:(NSInteger)partial;

@end
