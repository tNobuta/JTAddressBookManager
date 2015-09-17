//
//  AddressBookManager.m
//  youpinwei
//
//  Created by tmy on 14-9-25.
//  Copyright (c) 2014年 nobuta. All rights reserved.
//

#import "JTAddressBookManager.h"

#define CACHE_DIR @"JTAddressBook"
#define CACHE_FILE @"Contacts.dat"

#define PHONE_REGEX @"\\d+"

@implementation JTAddressBookManager
{
    ABAddressBookRef    _addressBook;
    NSMutableArray             *_allContacts;
    NSMutableDictionary *_contactsMapping;
    BOOL                _isUpdated;
}

+ (instancetype)defaultManager {
    static JTAddressBookManager  *DefaultManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DefaultManager = [[self alloc] init];
    });
    
    return DefaultManager;
}

- (id)init {
    if (self = [super init]) {
        NSString *cacheDir = [NSString stringWithFormat:@"%@/Library/Caches/%@", NSHomeDirectory(), CACHE_DIR];
        NSString *cachePath = [NSString stringWithFormat:@"%@/Library/Caches/%@/%@", NSHomeDirectory(), CACHE_DIR, CACHE_FILE];
        BOOL isDir = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDir isDirectory:&isDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        _allContacts = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
        if (!_allContacts) {
            _allContacts = [[NSMutableArray alloc] initWithCapacity:100];
        }
        
        _contactsMapping = [[NSMutableDictionary alloc] initWithCapacity:100];
        [self cacheContacts:_allContacts];
        
        _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    }
    
    return self;
}


- (void)requestAuthorization:(void(^)(bool granted))completion {
    ABAuthorizationStatus authorizationStatus = ABAddressBookGetAuthorizationStatus();
    if (authorizationStatus != kABAuthorizationStatusAuthorized) {
        ABAddressBookRequestAccessWithCompletion(_addressBook, ^(bool granted, CFErrorRef error) {
            if (completion) {
                completion(granted);
            }
        });
    }else {
        if (completion) {
            completion(YES);
        }
    }
}

- (ABAuthorizationStatus)currentAuthorizationStatus {
    ABAuthorizationStatus authorizationStatus = ABAddressBookGetAuthorizationStatus();
    return authorizationStatus;
}

- (void)fetchAllContacts: (void(^)(NSArray *allContacts, NSArray *updatedContacts))completionHandler {
    [self requestAuthorization:^(bool granted) {
        if (granted) {
            [self internalFetchContacts:completionHandler];
        }else {
            if (completionHandler) {
                completionHandler(nil, nil);
            }
        }
    }];
}

- (void)internalFetchContacts:(void(^)(NSArray *allContacts, NSArray *updatedContacts))completionHandler  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *updatedContacts  = [[NSMutableArray alloc] init];
        if (!_isUpdated) {
            CFArrayRef allPeopleArray = ABAddressBookCopyArrayOfAllPeople(_addressBook);
            NSArray *allContacts =  (__bridge_transfer NSArray *)allPeopleArray;
            
            NSError *regexError = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:PHONE_REGEX options:NSRegularExpressionCaseInsensitive error:&regexError];
            
            for (int i = 0; i < allContacts.count; ++i) {
                BOOL isNewContact = YES, isUpdatedContact = NO;
                JTAddressBookPerson *person = [[JTAddressBookPerson alloc] init];
                ABRecordRef record = (__bridge ABRecordRef)(allContacts[i]);
                NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
                NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
                NSMutableArray *phoneArray = [[NSMutableArray alloc] init];
                ABMultiValueRef  mutiPhones =  ABRecordCopyValue(record, kABPersonPhoneProperty);
                for (int j = 0; j < ABMultiValueGetCount(mutiPhones); ++j) {
                    NSString *phone = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(mutiPhones, j);
                    NSArray *matchResults = [regex matchesInString:phone options:0 range:NSMakeRange(0, phone.length)];
                    if (matchResults.count > 0) {
                        NSMutableString *phoneComponents = [[NSMutableString alloc] initWithString:@""];
                        for (NSTextCheckingResult *result in matchResults) {
                            [phoneComponents appendFormat:@"%@", [phone substringWithRange:result.range]];
                        }
                        
                        phone = [phoneComponents copy];
                    }
                    
                    if (phone.length > 11 && [phone hasPrefix:@"86"]) {
                        phone = [phone substringFromIndex:2];
                    }
                    
                    [phoneArray addObject:phone];
                    if (!_contactsMapping[phone]) {
                        isUpdatedContact = YES;
                    }else {
                        isNewContact = NO;
                    }
                }
                
                CFRelease(mutiPhones);
                person.firstName = firstName;
                person.lastName = lastName;
                person.phoneNumbers = phoneArray;
                
                if (isUpdatedContact) {
                    [updatedContacts addObject:person];
                }
                
                if (isNewContact) {
                    [_allContacts addObject:person];
                }
            }
            
            [self cacheContacts:updatedContacts];
            [self save];
            _isUpdated = YES;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler([_allContacts copy], updatedContacts);
            }
        });
    });
}

- (void)cacheContacts:(NSArray *)contacts {
    for (JTAddressBookPerson *person in contacts) {
        for (NSString *phone in person.phoneNumbers) {
            if (!_contactsMapping[phone]) {
                _contactsMapping[phone] = person;
            }
        }
    }
}

- (JTAddressBookPerson *)personForPhoneNumber:(NSString *)phoneNumber {
    if (phoneNumber && (NSNull *)phoneNumber != [NSNull null]) {
        return _contactsMapping[phoneNumber];
    }else {
        return nil;
    }
}

- (void)save {
    NSString *cachePath = [NSString stringWithFormat:@"%@/Library/Caches/%@/%@", NSHomeDirectory(), CACHE_DIR, CACHE_FILE];
    [NSKeyedArchiver archiveRootObject:_allContacts toFile:cachePath];
}

@end
