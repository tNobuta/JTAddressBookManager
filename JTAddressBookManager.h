//
//  AddressBookManager.h
//  youpinwei
//
//  Created by tmy on 14-9-25.
//  Copyright (c) 2014年 nobuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "JTAddressBookPerson.h"

@interface JTAddressBookManager : NSObject

+ (instancetype)defaultManager;
- (ABAuthorizationStatus)currentAuthorizationStatus;
- (void)requestAuthorization:(void(^)(bool granted))completion;
- (void)fetchAllContacts:(void(^)(NSArray *allContacts, NSArray *updatedContacts))completionHandler;
- (JTAddressBookPerson *)personForPhoneNumber:(NSString *)phoneNumber;

@end
