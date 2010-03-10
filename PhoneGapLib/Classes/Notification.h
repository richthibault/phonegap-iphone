//
//  Notification.h
//  PhoneGap
//
//  Created by Michael Nachbaur on 16/04/09.
//  Copyright 2009 Decaf Ninja Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "PhoneGapCommand.h"
#import "LoadingView.h"

@interface Notification : PhoneGapCommand <UIAlertViewDelegate> {
    UIAlertView* openURLAlert;
    NSInteger    alertCallbackId;
	LoadingView* loadingView;
}

- (void)alert:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void)activityStart:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)activityStop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)vibrate:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)loadingStart:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)loadingStop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
