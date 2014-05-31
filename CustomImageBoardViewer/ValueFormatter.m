//
//  ValueFormatter.m
//  SignalAnalyzer
//
//  Created by Craig on 20/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "ValueFormatter.h"

@implementation ValueFormatter

+(NSString *)convertBPS:(CGFloat)bitsPerSecond {
    NSString *suffix = @"bps";
    if (bitsPerSecond > 1024 * 1024 * 1024) {
        suffix = @"gbps";
        bitsPerSecond /= 1024 * 1024 * 1024;
    } else if (bitsPerSecond > 1024 * 1024) {
        suffix = @"mbps";
        bitsPerSecond /= 1024 * 1024;
    } else if (bitsPerSecond > 1024){
        suffix = @"kbps";
        bitsPerSecond /= 1024;
    }
//    if (bitsPerSecond > 1024) {
//        suffix = @"kbps";
//        bitsPerSecond /= 1024;
//    } else if (bitsPerSecond > 1024 * 1024) {
//        suffix = @"mbps";
//        bitsPerSecond /= 1024 * 1024;
//    } else if (bitsPerSecond > 1024 * 1024 * 1024) {
//        suffix = @"gbps";
//        bitsPerSecond /= 1024 * 1024 * 1024;
//    }
    if (bitsPerSecond <= 0) {
        return [NSString stringWithFormat:@"0.0%@", suffix];
    }
    return [NSString stringWithFormat:@"%.1f%@", bitsPerSecond, suffix];
}

+(NSString *)convertMilliSeconds:(CGFloat)ms {
    NSString *suffix = @"ms";
    ms *= 1000;
    return [NSString stringWithFormat:@"%.0f%@", ms, suffix];
}

+(NSString *)convertByte:(NSUInteger)bytes{
    NSString *suffix = @"Bytes";
    CGFloat fileSize = bytes;
    if (bytes > 1024 * 1024) {
        suffix = @"MB";
        fileSize /= 1024 * 1024;
    } else if (bytes > 1024) {
        suffix = @"KB";
        fileSize /= 1024;
    }
    return [NSString stringWithFormat:@"%.1f %@", fileSize, suffix];
}
@end
