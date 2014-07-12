//
//  CTSFeed.m
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import "CTSFeed.h"

@implementation CTSFeed

- (void)dealloc {
    [_title release];
    [_fDescription release];
    [_imageURLPath release];
    [_image release];
    
    [super dealloc];
}

@end
