//
//  Notification.m
//  PhoneGap
//
//  Created by Michael Nachbaur on 16/04/09.
//  Copyright 2009 Decaf Ninja Software. All rights reserved.
//

#import "Notification.h"
#import "Categories.h"

@implementation Notification

/**
 * Show a native alert window, with one or two buttons.  Depending on the options given, it can customize
 * the title, button labels, and can even be issued a callback to be invoked when a button is clicked.
 *
 * Additionally this command will issue a DOMEvent on the \c document element within JavaScript when a button
 * is clicked.  The \c alertClosed event will be fired, with \c buttonIndex and \c buttonLabel properties on
 * the supplied event object.
 *
 * @brief show a native alert window
 * @param arguments The message to display in the alert window
 * @param options dictionary of options, notable options including:
 *  - \c title {String} title text
 *  - \c okLabel {String=OK} label of the OK button
 *  - \c cancelLabel {String} optional label for a second Cancel button
 *  - \c onClose {Integer} callback ID used to invoke a function in JavaScript when the alert window closes
 * @see alertView:clickedButtonAtIndex
 */
- (void)alert:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    if (openURLAlert) {
        NSLog(@"Cannot open an alert when one already exists");
        return;
    }
	
	NSString* message      = [arguments objectAtIndex:0];
	NSString* title        = [options objectForKey:@"title"];
	NSString* okButton     = [options objectForKey:@"okLabel"];
	NSString* cancelButton = [options objectForKey:@"cancelLabel"];
	NSInteger onCloseId    = [(NSString*)[options objectForKey:@"onClose"] integerValue];
    
    if (!title)
        title = @"Alert";
    if (!okButton)
        okButton = @"OK";
    if (onCloseId)
        alertCallbackId = onCloseId; 
    
    openURLAlert = [[UIAlertView alloc] initWithTitle:title
                                              message:message
                                             delegate:self
                                    cancelButtonTitle:okButton
                                    otherButtonTitles:nil];
    if (cancelButton)
        [openURLAlert addButtonWithTitle:cancelButton];
    
	[openURLAlert show];
}

/**
 Callback invoked when an alert dialog's buttons are clicked.  This subsequently dispatches an event
 call to the JavaScript environment indicating which button was pressed.
 @brief callback when an alert button is clicked
 @see alert:arguments:withDict
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonLabel = [alertView buttonTitleAtIndex:buttonIndex];
    /* looks like Nachoman didn't finish this bit, but we can listen for alertClosed in the DOM.  works for me.  RT 
	 if (alertCallbackId) {
			NSString *buttonIndexStr = [NSString stringWithFormat:@"%d", buttonIndex];
			NSArray *arguments = [NSArray arrayWithObjects:buttonIndexStr, buttonLabel, nil];
			[self fireCallback:alertCallbackId withArguments:arguments];
			alertCallbackId = 0;
		} */
	NSLog(@"about to do callback");
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"(function(){ "
													 "var e = document.createEvent('Events'); "
													 "e.initEvent('alertClosed', 'false', 'false'); "
													 "e.buttonIndex = %d; "
													 "e.buttonLabel = \"%@\"; "
													 "document.dispatchEvent(e); "
                                                     "})()", buttonIndex, [buttonLabel stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]]];
    [openURLAlert release];
    openURLAlert = nil;
}

- (void)prompt:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSString* message = [arguments objectAtIndex:0];
	NSString* title   = [options objectForKey:@"title"];
	NSString* button  = [options objectForKey:@"buttonLabel"];
    
    if (!title)
        title = @"Alert";
    if (!button)
        button = @"OK";
    
	//UIAlertView *openURLAlert 
	openURLAlert = [[UIAlertView alloc]
								 initWithTitle:title
								 message:message delegate:nil cancelButtonTitle:button otherButtonTitles:nil];
	[openURLAlert show];
	[openURLAlert release];
}

- (void)activityStart:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSLog(@"Activity starting");
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;
}

- (void)activityStop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSLog(@"Activitiy stopping ");
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = NO;
}

- (void)vibrate:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)loadingStart:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (loadingView == nil) 
	{
		NSLog(@"Loading start");
		UIViewController* c = [super appViewController];
		loadingView = [LoadingView loadingViewInView:c.view];
		
		NSRange minMaxDuration = NSMakeRange(2, 3600);// 1 hour max? :)
		// the view will be shown for a minimum of this value if durationKey is not set
		loadingView.minDuration = [options integerValueForKey:@"minDuration" defaultValue:minMaxDuration.location withRange:minMaxDuration];
		
		// if there's a duration set, we set a timer to close the view
		NSString* durationKey = @"duration";
		if ([options valueForKey:durationKey]) {
			NSTimeInterval duration = [options integerValueForKey:durationKey defaultValue:minMaxDuration.location withRange:minMaxDuration];
			[self performSelector:@selector(loadingStop:withDict:) withObject:nil afterDelay:duration];
		}
	}
}

- (void)loadingStop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (loadingView != nil) 
	{
		NSLog(@"Loading stop");
		NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:loadingView.timestamp] - loadingView.minDuration;
		
		if (diff >= 0) {
			[loadingView removeView]; // the superview will release (see removeView doc), so no worries for below
			loadingView = nil;
		} else {
			[self performSelector:@selector(loadingStop:withDict:) withObject:nil afterDelay:-1*diff];
		}
	}
}

@end
