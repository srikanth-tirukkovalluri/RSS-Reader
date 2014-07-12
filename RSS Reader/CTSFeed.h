//
//  CTSFeed.h
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import <Foundation/Foundation.h>

@interface CTSFeed : NSObject

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *fDescription;
@property (nonatomic, retain) NSString *imageURLPath;
@property (nonatomic, retain) UIImage *image;

@end
