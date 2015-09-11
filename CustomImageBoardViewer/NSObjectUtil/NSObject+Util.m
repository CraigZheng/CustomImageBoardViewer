//
//  NSObject+Util.m
//  DartCrowdSourcingLib
//
//  Created by Craig on 8/09/2015.
//  Copyright (c) 2015 Optus. All rights reserved.
//

#import "NSObject+Util.h"
#import "PropertyAttribute.h"

@implementation NSObject (Util)

static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    //printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            // it's a C primitive type:
            /*
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
             */
            NSString *name = [[NSString alloc] initWithBytes:attribute + 1 length:strlen(attribute) - 1 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            NSString *name = [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    return "";
}

+ (PropertyAttributeType)getPropertyAttributeType:(objc_property_t) property {
    PropertyAttributeType type = PropertyAttributeTypeReadWrite;
    const char *attributes = property_getAttributes(property);
    //printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    NSString *attributeTypes = [[NSString alloc] initWithUTF8String:attributes];
    for (NSString *attribute in [attributeTypes componentsSeparatedByString:@","]) {
        if ([attribute isEqualToString:@"R"]) {
            type = PropertyAttributeTypeReadOnly;
            break;
        }
    }
    return type;
}

+ (NSDictionary *)classPropsFor:(Class)klass{
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            PropertyAttribute *attribute = [PropertyAttribute new];
            attribute.propertyName = [NSString stringWithUTF8String:propName];
            attribute.propertyType = [NSString stringWithUTF8String:propType];
            attribute.propertyAttributeType = [self getPropertyAttributeType:property];

            [results setObject:attribute forKey:attribute.propertyName];
        }
    }
    free(properties);
    
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}

@end
