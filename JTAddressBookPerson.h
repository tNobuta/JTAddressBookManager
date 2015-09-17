//
//  JTAddressBookPerson.h
//  youpinwei
//
//  Created by tmy on 14-9-25.
//  Copyright (c) 2014年 nobuta. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JTAddressBookPerson : NSObject<NSCoding>

@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSArray  *phoneNumbers;

@end
