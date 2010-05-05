/*
 *  Camera.h
 *
 *  Created by Nitobi on 12/12/08.
 *  Copyright 2008 Nitobi. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "PhoneGapCommand.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface CameraPicker : UIImagePickerController
{
	NSString* successCallback;
	NSString* errorCallback;
	NSInteger quality;
}

@property NSInteger quality;
@property (retain) NSString* successCallback;
@property (retain) NSString* errorCallback;

- (void) dealloc;

@end

@interface Camera : PhoneGapCommand<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
	CameraPicker* pickerController;
	NSData* lastImageData;
	NSString* lastImageMimeType;
	//NSMutableData* receivedData;
}

@property (readwrite,nonatomic,retain) NSData* lastImageData;
@property (readwrite,nonatomic,retain) NSString* lastImageMimeType;
//@property (readwrite,nonatomic,retain) NSMutableData* receivedData;

/*
 * getPicture
 *
 * arguments:
 *	1: this is the javascript function that will be called with the results, the first parameter passed to the
 *		javascript function is the picture as a Base64 encoded string
 *  2: this is the javascript function to be called if there was an error
 * options:
 *	quality: integer between 1 and 100
 */
- (void) getMovie:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) getPicture:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) postLastPickedImage:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) postImage:(UIImage*)anImage withFilename:(NSString*)filename toUrl:(NSURL*)url;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
//- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo;
- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker;

- (void) dealloc;

@end



