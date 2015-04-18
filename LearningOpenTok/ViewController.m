//
//  ViewController.h
//  Getting Started
//
//  Created by Jeff Swartz on 11/19/14.
//  Copyright (c) 2014 TokBox, Inc. All rights reserved.

#import "ViewController.h"
#import <OpenTok/OpenTok.h>

@interface ViewController ()
<OTSessionDelegate, OTPublisherDelegate>
@property (weak, nonatomic) IBOutlet UIView *videoContainerView;
@property (weak, nonatomic) IBOutlet UIView *publisherView;

@end

@implementation ViewController {
    OTSession* _session;
    OTPublisher* _publisher;
    NSString* _archiveId;
    NSString* _apiKey;
    NSString* _sessionId;
    NSString* _token;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getSessionCredentials];
}

- (void)getSessionCredentials
{
    NSString* urlPath = SAMPLE_SERVER_BASE_URL;
    urlPath = [urlPath stringByAppendingString:@"/session"];
    NSURL *url = [NSURL URLWithString: urlPath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error){
            NSLog(@"Error,%@, URL: %@", [error localizedDescription],urlPath);
        }
        else{
            NSDictionary *roomInfo = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            _apiKey = [roomInfo objectForKey:@"apiKey"];
            _token = [roomInfo objectForKey:@"token"];
            _sessionId = [roomInfo objectForKey:@"sessionId"];
            
            if(!_apiKey || !_token || !_sessionId) {
                NSLog(@"Error invalid response from server, URL: %@",urlPath);
            } else {
                [self doConnect];
            }
        }
    }];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UIUserInterfaceIdiomPhone == [[UIDevice currentDevice]
                                      userInterfaceIdiom])
    {
        return NO;
    } else {
        return YES;
    }
}
#pragma mark - OpenTok methods

- (void)doConnect
{
    // Initialize a new instance of OTSession and begin the connection process.
    _session = [[OTSession alloc] initWithApiKey:_apiKey
                                       sessionId:_sessionId
                                        delegate:self];
    OTError *error = nil;
    [_session connectWithToken:_token error:&error];
    if (error)
    {
        NSLog(@"Unable to connect to session (%@)",
              error.localizedDescription);
    }
}

- (void)doPublish
{
    _publisher = [[OTPublisher alloc]
                  initWithDelegate:self];
    
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error)
    {
        NSLog(@"Unable to publish (%@)",
              error.localizedDescription);
    }
    
    [_publisher.view setFrame:CGRectMake(0, 0, _publisherView.bounds.size.width,
                                         _publisherView.bounds.size.height)];
    [_publisherView addSubview:_publisher.view];

}


- (void)cleanupPublisher {
    [_publisher.view removeFromSuperview];
    _publisher = nil;
}

# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)",
     session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
}

- (void)session:(OTSession*)session
streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@)", stream.streamId);
}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
}

- (void)  session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void)    session:(OTSession *)session
connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
streamCreated:(OTStream *)stream
{
    NSLog(@"Now publishing.");
}

- (void)publisher:(OTPublisherKit*)publisher
streamDestroyed:(OTStream *)stream
{
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher
didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}

@end