//
//  CTSFeedTableViewCell.h
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import <UIKit/UIKit.h>

@interface CTSFeedTableViewCell : UITableViewCell

@property (nonatomic, assign) IBOutlet UILabel *feedTitleLabel;
@property (nonatomic, assign) IBOutlet UILabel *feedDescriptionLabel;
@property (nonatomic, assign) IBOutlet UIImageView *feedImageView;
@property (nonatomic, assign) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
