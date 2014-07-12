//
//  CTSLazyImageDownloader.h
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import <Foundation/Foundation.h>
@class CTSLazyImageDownloader;

// CTSLazyImageDownloaderDelegate notifies the delegate when the image download is complete
@protocol CTSLazyImageDownloaderDelegate <NSObject>

@required
- (void)imageDownloader:(CTSLazyImageDownloader *)imageDownloader didFinishDownloadingImage:(UIImage *)image forCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface CTSLazyImageDownloader : NSObject

@property (nonatomic, assign) id <CTSLazyImageDownloaderDelegate> delegate;

// Downloads the image at the specified URL for a given indexPath.
// This method fires itself asynchronously,
// so the method returns immediately and delegate is notified after the download is complete.
- (void)loadImageWithURLPath:(NSString *)imageURLPath forCellAtIndexPath:(NSIndexPath *)indexPath;

@end
