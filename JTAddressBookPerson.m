//
//  JTAddressBookPerson.m
//  youpinwei
//
//  Created by tmy on 14-9-25.
//  Copyright (c) 2014年 nobuta. All rights reserved.
//

#import "JTAddressBookPerson.h"

@implementation JTAddressBookPerson
{
    
}

- (NSString *)fullName {
    NSString *firstName = self.firstName != nil ? self.firstName : @"";
    NSString *lastName = self.lastName != nil ? self.lastName : @"";
    return [NSString stringWithFormat:@"%@%@", lastName, firstName];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.firstName forKey:@"firstName"];
    [encoder encodeObject:self.lastName forKey:@"lastName"];
    [encoder encodeObject:self.phoneNumbers forKey:@"phoneNumbers"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        self.phoneNumbers = [decoder decodeObjectForKey:@"phoneNumbers"];
    }
    return self;
}

@end
