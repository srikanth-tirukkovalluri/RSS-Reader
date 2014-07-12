//
//  CTSLazyImageDownloader.m
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import "CTSLazyImageDownloader.h"

@interface CTSLazyImageDownloader ()

@end

@implementation CTSLazyImageDownloader

- (void)loadImageWithURLPath:(NSString *)imageURLPath forCellAtIndexPath:(NSIndexPath *)indexPath{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURLPath]];
        UIImage *image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            [self.delegate imageDownloader:self didFinishDownloadingImage:image forCellAtIndexPath:indexPath];
        });
    });
}

- (void)dealloc {
    [super dealloc];
}

@end
