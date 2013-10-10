//
//  ZumeroRule.h
//  Zumero
//
//  Created by Paul Roub on 2/25/13.
//  Copyright (c) 2013 Zumero. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZumeroRule : NSObject

+ (NSString *) action_default;
+ (NSString *) action_accept;
+ (NSString *) action_ignore;
+ (NSString *) action_reject;
+ (NSString *) action_column_merge;
+ (NSString *) action_attempt_text_merge;
+ (NSString *) situation_del_after_mod;
+ (NSString *) situation_mod_after_del;
+ (NSString *) situation_mod_after_mod;

@end
