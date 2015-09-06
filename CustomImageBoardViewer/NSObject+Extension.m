//
//  NSObject+Extension.m
//  CustomImageBoardViewer
//
//  Created by Craig on 9/03/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "NSObject+Extension.h"

@implementation NSObject (Extension)

-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name {
    if ([[dict valueForKey:name] isEqual:[NSNull null]]) {
        return nil;
    }
    id value = [dict valueForKey:name];
    return value;
}

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
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [NSString stringWithUTF8String:propType];
            [results setObject:propertyType forKey:propertyName];
        }
    }
    free(properties);
    
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}


#pragma mark - hex to UIColor, copied from internet
- (UIColor *) colorForHex:(NSString *)hexColor {
    @try {
        hexColor = [[hexColor stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]
                     ] uppercaseString];
        
        // String should be 6 or 7 characters if it includes '#'
        if ([hexColor length] < 6)
            return [UIColor blackColor];
        
        // strip # if it appears
        if ([hexColor hasPrefix:@"#"])
            hexColor = [hexColor substringFromIndex:1];
        
        // if the value isn't 6 characters at this point return
        // the color black
        if ([hexColor length] != 6)
            return [UIColor blackColor];
        
        // Separate into r, g, b substrings
        NSRange range;
        range.location = 0;
        range.length = 2;
        
        NSString *rString = [hexColor substringWithRange:range];
        
        range.location = 2;
        NSString *gString = [hexColor substringWithRange:range];
        
        range.location = 4;
        NSString *bString = [hexColor substringWithRange:range];
        
        // Scan values
        unsigned int r, g, b;
        [[NSScanner scannerWithString:rString] scanHexInt:&r];
        [[NSScanner scannerWithString:gString] scanHexInt:&g];
        [[NSScanner scannerWithString:bString] scanHexInt:&b];
        
        return [UIColor colorWithRed:((float) r / 255.0f)
                               green:((float) g / 255.0f)
                                blue:((float) b / 255.0f)
                               alpha:1.0f];
    }
    @catch (NSException *exception) {
        DLog(@"exception");
    }
    @finally {
        
    }
    return [UIColor blackColor];
}

@end