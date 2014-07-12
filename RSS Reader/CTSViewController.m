//
//  CTSViewController.m
//  RSS Reader
//
//  Created by Srikanth on 7/12/14.
//
//

#import "CTSViewController.h"
#import "CJSONDeserializer.h"
#import "CTSFeedTableViewCell.h"
#import "CTSFeed.h"

@interface CTSViewController ()

// This array holds the list of parsed Feed objects
@property (nonatomic, retain) NSMutableArray *feeds;

// This array holds the list of image url's being downloaded to avoid duplicate downloads.
@property (nonatomic, retain) NSMutableArray *loadingImageURLPaths;

// Pull to refresh control
@property (nonatomic, retain) UIRefreshControl *refreshControl;

@end

@implementation CTSViewController

# pragma mark -
# pragma mark View Controller Default Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize Pull to refresh control
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    // Initialize current view controller as JSON feed download delegate
    self.jsonFeedDownloadDelegate = self;
    
    // Start downloading data
    [self getObjectFromJSONData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark -
# pragma mark Table View DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.feeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CTSFeedTableViewCell *cell=  (CTSFeedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"FeedTableViewCell"];

    // Get respective feed object and initialize tableview cell
    CTSFeed *feed = [self.feeds objectAtIndex:indexPath.row];
    
    cell.feedTitleLabel.text = feed.title;
    cell.feedDescriptionLabel.text = feed.fDescription;
    cell.feedImageView.image = nil;
    cell.activityIndicator.hidden = YES;
    
    // If image for a Feed is already downloaded, show it.
    // Else if image URL Path is available for the feed and its not already being downloaded, initiate a image download.
    // Else if the image is being downloaded, then show the spinner.
    // Else show no-image available image(as a place holder).
    if (feed.image) {
        cell.feedImageView.image = feed.image;
    } else if (feed.imageURLPath && ![self.loadingImageURLPaths containsObject:feed.imageURLPath]) {
        [self.loadingImageURLPaths addObject:feed.imageURLPath];
        
        CTSLazyImageDownloader *imageDownloader = [CTSLazyImageDownloader new];
        imageDownloader.delegate = self;
        [imageDownloader loadImageWithURLPath:feed.imageURLPath forCellAtIndexPath:indexPath];
        
        // Show activity inidcator while download is in progress
        cell.activityIndicator.hidden = NO;
        
    } else if ([self.loadingImageURLPaths containsObject:feed.imageURLPath]) {
        cell.activityIndicator.hidden = NO;
        
    } else if (feed.imageURLPath.length == 0) {
        cell.feedImageView.image = [UIImage imageNamed:@"no-image"];
    }
    
    // Update the cell layout on main thread as UI updates are effective only when they are done on main thread
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self layoutElementsInCell:cell forRowAtIndexPath:indexPath];
    });
    
    return cell;
}

// For dynamic tableview cell height, calculate individual label heights(title, description) depending the text style and font size.
// Add up the heights and padding around the lables to calculate the overall cell height.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CTSFeed *feed = [self.feeds objectAtIndex:indexPath.row];
    
    CGSize titleLabelSize = [feed.title sizeWithFont:[UIFont boldSystemFontOfSize:FEED_CELL_TITLE_LABEL_FONT_SIZE]
                                                        constrainedToSize:CGSizeMake(FEED_CELL_TITLE_LABEL_MAX_WIDTH, 10000)
                                                            lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize descriptionLabelSize = [feed.fDescription sizeWithFont:[UIFont systemFontOfSize:FEED_CELL_DESCRIPTION_LABEL_FONT_SIZE]
                                   constrainedToSize:CGSizeMake(FEED_CELL_DESCRIPTION_LABEL_MAX_WIDTH, 10000)
                                       lineBreakMode:NSLineBreakByWordWrapping];
    
    // TOP_PADDING + TITLE_LABLE_HEIGHT + MIDDLE_PADDING + DESCRIPTION_LABLE_HEIGHT + BOTTOM_PADDING
    CGFloat calculatedCellHeight = FEED_CELL_ELEMENTS_TOP_PADDING + titleLabelSize.height + FEED_CELL_ELEMENTS_MIDDLE_PADDING + descriptionLabelSize.height + FEED_CELL_ELEMENTS_BOTTOM_PADDING;
    
    // If the cell height is less than 100px which is minimum as considered, use the minimum height, else use calculated height.
    if (calculatedCellHeight < 100) {
        return 100;
    }
    
    return calculatedCellHeight;
}

# pragma mark -
# pragma mark Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark -
# pragma mark Utility Methods

// Loads the JSON data from the webservice and creates "Feed" model objects

- (void)getObjectFromJSONData {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Initialize variables
        self.feeds = [NSMutableArray array];
        self.loadingImageURLPaths = [NSMutableArray array];
        
//        // Loading JSON from local file(for testing only)
//        // Local JSON feed URL
//        NSString *rssLocalPath = [[NSBundle mainBundle] pathForResource:@"json_data" ofType:@"txt"];
//        
//        NSError *jsonerror;
//        NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:rssLocalPath]];
//        NSString *jsonString = [[NSString alloc] initWithData: jsonData encoding: NSStringEncodingConversionAllowLossy];
//
//        NSLog(@"jsonString %@", jsonString);

        
        // Download JSON feed from web
        NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:RSS_FEED_URL]];
        
        // The JSON data that is being downloaded is not in proper format, some special characters are present that is preventing the JSON parsing.
        // So to avoid that, first converting the JSON data into string by using Lossy encoding and then converting that string back to NSData using UTF8 encoding.
        NSString *jsonString = [[NSString alloc] initWithData: jsonData encoding: NSStringEncodingConversionAllowLossy];
        NSData *restoredJSONData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error = nil;

        NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:restoredJSONData error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            if (error && [self.jsonFeedDownloadDelegate respondsToSelector:@selector(didFailedDownloadingJSONWithError:)]) {
                [self.jsonFeedDownloadDelegate didFailedDownloadingJSONWithError:error];
            }

            if (!error) {
                [self.jsonFeedDownloadDelegate didFinishDownloadingJSONWithDictionary:dictionary];
            }
        });
    });
}

// Called from tableView:cellForRowAtIndexPath: to layout labels in cells dynamically
- (void)layoutElementsInCell:(CTSFeedTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CTSFeed *feed = [self.feeds objectAtIndex:indexPath.row];
    
    // Preserve Title label's original frame for ease
    CGRect currentFeedTitleLabelFrame = cell.feedTitleLabel.frame;

    // Calculate Title label size
    CGSize calculatedTitleLabelSize = [feed.title sizeWithFont:[UIFont boldSystemFontOfSize:FEED_CELL_TITLE_LABEL_FONT_SIZE]
                                   constrainedToSize:CGSizeMake(FEED_CELL_TITLE_LABEL_MAX_WIDTH, MAX_CELL_HEIGHT)
                                       lineBreakMode:NSLineBreakByWordWrapping];
    
    // Update title label frame
    cell.feedTitleLabel.frame = CGRectMake(currentFeedTitleLabelFrame.origin.x, currentFeedTitleLabelFrame.origin.y, currentFeedTitleLabelFrame.size.width, calculatedTitleLabelSize.height);
    
    // Preserve Description label's original frame for ease
    CGRect currentFeedDescriptionLabelFrame = cell.feedDescriptionLabel.frame;

    // Calculate Description label size
    CGSize calculatedDescriptionLabelSize = [feed.fDescription sizeWithFont:[UIFont systemFontOfSize:FEED_CELL_DESCRIPTION_LABEL_FONT_SIZE]
                                                constrainedToSize:CGSizeMake(FEED_CELL_DESCRIPTION_LABEL_MAX_WIDTH, MAX_CELL_HEIGHT)
                                                    lineBreakMode:NSLineBreakByWordWrapping];
    
    // Save new updated Y Coordinate for second level elements(Description & Image View)
    int secondLevelElementsYCoordinate = currentFeedTitleLabelFrame.origin.y + calculatedTitleLabelSize.height + FEED_CELL_ELEMENTS_TOP_PADDING;
    
    // Update Description label frame
    cell.feedDescriptionLabel.frame = CGRectMake(currentFeedDescriptionLabelFrame.origin.x, secondLevelElementsYCoordinate, currentFeedDescriptionLabelFrame.size.width, calculatedDescriptionLabelSize.height);
    
    CGRect currentFeedImageViewFrame = cell.feedImageView.frame;

    // Update Image View frame
    cell.feedImageView.frame = CGRectMake(currentFeedImageViewFrame.origin.x, secondLevelElementsYCoordinate, currentFeedImageViewFrame.size.width, currentFeedImageViewFrame.size.height);
}

// Return dynamic row heights
- (CGFloat)calculateHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CTSFeed *feed = [self.feeds objectAtIndex:indexPath.row];
    
    CGSize titleLabelSize = [feed.title sizeWithFont:[UIFont boldSystemFontOfSize:FEED_CELL_TITLE_LABEL_FONT_SIZE]
                                   constrainedToSize:CGSizeMake(FEED_CELL_TITLE_LABEL_MAX_WIDTH, MAX_CELL_HEIGHT)
                                       lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize descriptionLabelSize = [feed.fDescription sizeWithFont:[UIFont systemFontOfSize:FEED_CELL_DESCRIPTION_LABEL_FONT_SIZE]
                                                constrainedToSize:CGSizeMake(FEED_CELL_DESCRIPTION_LABEL_MAX_WIDTH, MAX_CELL_HEIGHT)
                                                    lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat calculatedCellHeight = FEED_CELL_ELEMENTS_TOP_PADDING + titleLabelSize.height + FEED_CELL_ELEMENTS_TOP_PADDING + descriptionLabelSize.height + FEED_CELL_ELEMENTS_TOP_PADDING;
    
    return calculatedCellHeight;
}

# pragma mark -
# pragma mark Action Methods

// Reload JSON Data & Refresh TableView
- (void)refreshTable {
    [self getObjectFromJSONData];
    
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}



# pragma mark -
# pragma mark JSONFeedDownload Delegate Methods

- (void)didFinishDownloadingJSONWithDictionary:(NSDictionary *)feedDictionary {
    NSArray *feedsArray = [feedDictionary valueForKey:@"rows"];
    
    for (NSDictionary *feedDetails in feedsArray) {
        // Exclude feeds which don't have title
        if ([[feedDetails valueForKey:@"title"] isKindOfClass:[NSNull class]]) {
            continue;
        }
        
        // Create Feed objects
        CTSFeed *feed = [CTSFeed new];
        feed.title = [feedDetails valueForKey:@"title"];
        feed.fDescription = [[feedDetails valueForKey:@"description"] isKindOfClass:[NSNull class]] ? nil : [feedDetails valueForKey:@"description"];
        feed.imageURLPath = [[feedDetails valueForKey:@"imageHref"] isKindOfClass:[NSNull class]] ? nil : [feedDetails valueForKey:@"imageHref"];
        
        [self.feeds addObject:feed];
        
        [feed release];
    }
    
    self.navigationItem.title = [feedDictionary valueForKey:@"title"];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


# pragma mark -
# pragma mark LazyImagDownloader Delegate Methods

- (void)imageDownloader:(CTSLazyImageDownloader *)imageDownloader didFinishDownloadingImage:(UIImage *)image forCellAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self) {
        NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
        CTSFeed *feed = [self.feeds objectAtIndex:indexPath.row];
        
        if ([indexPathsForVisibleRows containsObject:indexPath] && [self.loadingImageURLPaths containsObject:feed.imageURLPath]) {
            
            CTSFeedTableViewCell *feedTableViewCell = (CTSFeedTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
            
            if (image) {
                feed.image = image;
            } else {
                feed.image = [UIImage imageNamed:@"no-image"];
            }
            
            feedTableViewCell.feedImageView.image = image;
            feedTableViewCell.activityIndicator.hidden = YES;
            feedTableViewCell.feedImageView.image = feed.image;
            
            [self.loadingImageURLPaths removeObject:feed.imageURLPath];
        }
        
        // Release the CTSLazyImageDownloader instance.
        [imageDownloader release];
    }
}

- (void)dealloc {
    
    self.feeds = nil;
    self.loadingImageURLPaths = nil;
    self.refreshControl = nil;
    
    [super dealloc];
}

@end
