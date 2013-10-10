//
//  ZumeroACL.h
//  zumero-ios
//
//  Created by Paul Roub on 2/13/13.
//  Copyright (c) 2013 SourceGear, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZumeroACL : NSObject

+ (NSString *) result_allow;
+ (NSString *) result_deny;

+ (NSString *) who_anyone;
+ (NSString *) who_any_auth;
+ (NSString *) who_user:(NSString *)username;

+ (NSString *) op_auth_add_user;
+ (NSString *) op_pull;
+ (NSString *) op_all;

+ (NSString *) op_create_table;
+ (NSString *) op_tbl_add_row;
+ (NSString *) op_tbl_modify_row;
+ (NSString *) op_tbl_add_column;
+ (NSString *) op_add_rule;
+ (NSString *) op_auth_set_password;
+ (NSString *) op_auth_set_acl_entry;
+ (NSString *) op_create_dbfile;

@end
