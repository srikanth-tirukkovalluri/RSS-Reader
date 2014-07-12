//
//  CTSViewController.h
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import <UIKit/UIKit.h>
#import "CTSLazyImageDownloader.h"

@protocol JSONFeedDownloadDelegate <NSObject>

@optional
- (void)didFailedDownloadingJSONWithError:(NSError *)error;

@required
- (void)didFinishDownloadingJSONWithDictionary:(NSDictionary *)feedDictionary;

@end

@interface CTSViewController : UITableViewController <CTSLazyImageDownloaderDelegate, JSONFeedDownloadDelegate>

@property (nonatomic, assign) id <JSONFeedDownloadDelegate> jsonFeedDownloadDelegate;

@end
