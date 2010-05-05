//
//  Camera.m
//  PhoneGap
//
//  Created by Shazron Abdullah on 15/07/09.
//  Copyright 2009 Nitobi. All rights reserved.
//

#import "Camera.h"
#import "NSData+Base64.h"
#import "Categories.h"

@implementation Camera

@synthesize lastImageData;
@synthesize lastImageMimeType;
//@synthesize receivedData;

- (void) getMovie:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	NSString* successCallback = nil, *errorCallback = nil;
	
	if (argc > 0) successCallback = [arguments objectAtIndex:0];
	if (argc > 1) errorCallback = [arguments objectAtIndex:1];
	
	if (argc < 1) {
		NSLog(@"Camera.getMovie: Missing 1st parameter.");
		return;
	}
	
	NSString* sourceTypeString = [options valueForKey:@"sourceType"];
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera; // default
	if (sourceTypeString != nil) {
		sourceType = (UIImagePickerControllerSourceType)[sourceTypeString intValue];
	}
	
	bool hasCamera = [UIImagePickerController isSourceTypeAvailable:sourceType];
	if (!hasCamera) {
		NSLog(@"Camera.getMovie: source type %d not available.", sourceType);
		return;
	}
	
	if (pickerController == nil) {
		pickerController = [[CameraPicker alloc] init];
	}
	
	pickerController.delegate = self;
	pickerController.sourceType = sourceType;
	
	// get all media types and make sure movie is one of them
	pickerController.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:pickerController.sourceType];
	
	//NSLog(@"Camera.getMovie: got %d media types.", [pickerController.mediaTypes count]);
	
	if(![pickerController.mediaTypes containsObject:(NSString *)kUTTypeMovie]) {
		NSLog(@"Camera.getMovie: video not available.");
		if (errorCallback) {
			NSString* jsString = [[NSString alloc] initWithFormat:@"%@(\"%@\");", errorCallback, @"Video is not available on this device."];
			[webView stringByEvaluatingJavaScriptFromString:jsString];
			[jsString release];
		}
		return;
	}
	
	// limit to "movie"
	pickerController.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	pickerController.successCallback = successCallback;
	pickerController.errorCallback = errorCallback;
	pickerController.quality = [options integerValueForKey:@"quality" defaultValue:100 withRange:NSMakeRange(0, 100)];
	
	[[super appViewController] presentModalViewController:pickerController animated:YES];
}

- (void) getPicture:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSUInteger argc = [arguments count];
	NSString* successCallback = nil, *errorCallback = nil;
	
	if (argc > 0) successCallback = [arguments objectAtIndex:0];
	if (argc > 1) errorCallback = [arguments objectAtIndex:1];
	
	if (argc < 1) {
		NSLog(@"Camera.getPicture: Missing 1st parameter.");
		return;
	}
	
	NSString* sourceTypeString = [options valueForKey:@"sourceType"];
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera; // default
	if (sourceTypeString != nil) {
		sourceType = (UIImagePickerControllerSourceType)[sourceTypeString intValue];
	}
	
	bool hasCamera = [UIImagePickerController isSourceTypeAvailable:sourceType];
	if (!hasCamera) {
		NSLog(@"Camera.getPicture: source type %d not available.", sourceType);
		return;
	}
	
	if (pickerController == nil) {
		pickerController = [[CameraPicker alloc] init];
	}

	// limit to "image"
	pickerController.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
	pickerController.delegate = self;
	pickerController.sourceType = sourceType;
	pickerController.successCallback = successCallback;
	pickerController.errorCallback = errorCallback;
	pickerController.quality = [options integerValueForKey:@"quality" defaultValue:100 withRange:NSMakeRange(0, 100)];
	
	[[super appViewController] presentModalViewController:pickerController animated:YES];
}

/*- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
	CameraPicker* cameraPicker = (CameraPicker*)picker;
	CGFloat quality = (double)cameraPicker.quality / 100.0; 
	NSData* data = UIImageJPEGRepresentation(image, quality);

	[picker dismissModalViewControllerAnimated:YES];
	
	if (cameraPicker.successCallback) {
		NSString* jsString = [[NSString alloc] initWithFormat:@"%@(\"%@\");", cameraPicker.successCallback, [data base64EncodedString]];
		[webView stringByEvaluatingJavaScriptFromString:jsString];
		[jsString release];
	}
}*/

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	//NSData* data;
	CameraPicker* cameraPicker = (CameraPicker*)picker;
	CGFloat quality = (double)cameraPicker.quality / 100.0; 
	if ([mediaType isEqualToString:@"public.image"]){
		UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
		self.lastImageData = UIImageJPEGRepresentation(image, quality);
		self.lastImageMimeType = @"image/jpg";
	} else if ([mediaType isEqualToString:@"public.movie"]){
		NSURL *mediaURL	= [info objectForKey:UIImagePickerControllerMediaURL];
		self.lastImageData = [NSData dataWithContentsOfURL:mediaURL];
		self.lastImageMimeType = @"video/mp4";
	}
	
	[picker dismissModalViewControllerAnimated:YES];
	
	if (cameraPicker.successCallback) {
		// don't send back video data, anything over a minute crashes the app.  call postLastPickedImage from Javascript instead.
		NSString* jsArg;
		if ([mediaType isEqualToString:@"public.image"]){
			jsArg = [lastImageData base64EncodedString];
		} else {
			jsArg = @"";
		}
		NSString* jsString = [[NSString alloc] initWithFormat:@"%@(\"%@\");", cameraPicker.successCallback, jsArg];
		[webView stringByEvaluatingJavaScriptFromString:jsString];
		[jsString release];
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[picker dismissModalViewControllerAnimated:YES];
}

- (void) postImage:(UIImage*)anImage withFilename:(NSString*)filename toUrl:(NSURL*)url 
{
	NSString *boundary = @"----BOUNDARY_IS_I";

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
	[req setHTTPMethod:@"POST"];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSData* imageData;
	NSString* mimeType;
	if(anImage==nil) {
		imageData = lastImageData;
		mimeType = lastImageMimeType;
	} else {
		imageData = UIImagePNGRepresentation(anImage);
		mimeType = @"image/png";
	}
	
	//NSLog(@"Posting imageData length %@",[imageData length]);
	
	// adding the body
	NSMutableData *postBody = [NSMutableData data];
	
	// post binary file
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
	//[postBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];
	//[postBody appendData:[[NSString stringWithFormat:@"R0lGODlhMgBKAPcAAD0rPzQqPwAvSQwuRwAySwsxSQY5UQo7UwU3UBQuRhwvRRUwRxIxSRowRxs1 TBg8UyQuRCwtQycySDMtQTotQTc2STA9UQ9AVxJDWRlJXh1MYTpGWCBPYyRTZilXaSxabCdVaDJf cDZiczlmdj1peUQrPkwqPVMpO10nOVsqO1knOWYnN2InOGMqO2wmNmwrO3MlNXIsO3wkM3spN3cw P0MuQUwuQUMyRUg5SlMzRFU4SE83SGg4R3o6RUpHVllIUlVDT1JVZENse1podWNHVXZHU2pQVXda Y2ZVYnhja3t2e3RqcEp0gk54hVR9iVB6hmN9hHqCcFqCjVeAi16GkWSLlWiOmGCHkm2TnH6EjHWN lXqLknqHkHGWnnKYn3uanXiTmW6EjW2YoHOZoHmdoI0iL4EhL4QkMosjMYQrOZMhLpshLZ4pNJYn M5YyPYkxP6YfKqwfKbQeKLwdJrcdJ6MgLK0kLqQmMakmMagqNKgyPLojLLQjLbYqM740PL01PYs7 RJk5RKg7RLg7QohASoZIU5dCTJdLU5BUWJ1dZJJdZoNfZ41ze4h6fZllbJRmaJNsc5lrcZV0eYht bqpETKxMVKVNVKpTWqdWXLRES7tESbFLUrtVVaJaYrpoXKZmaap3cNkXH8QcJcwcJNUbI9kaIcQk LMwkK80lLcMtNMosM8UwN8IzOsI4PtIiKdIgJ8M7QMt7a8pSToV9hYl5gY6WfpuKeJOVfZmVfImI dKuTea+ZfrGLdsOUd9qNb9mPcdqZesiIcuONbuWTdISGioeamZWEg5Sbg52VjZiaiZiblYCLkYyl n4Khn5aonZ6kiommoZasoZ+woKyKgaSekbSZg6Odi6Sojaqvk6apl6yxlLiljbauk7qzlbi3m6i1 obO7ori7oL7Co8WXgcuoi8Gtkcu4hsO8ncu2ldSmhtG2jNe5k+i2jMzBl9rEmdfBjMPEo8vIo9fN otzSpPPKl/XTnOfFl+TWpe3bpefYpfPepePOoPbhpv3kpv3mqP/pqSH5BAAAAAAALAAAAAAyAEoA AAj+APsJ7OevoEGDAwvWU2euYcN3D3u9+0eRYr9/AjFivEhw4LxjtUKKvNXLHbprx26JzMWLl61d uHIFC6YrSq5dInPqHOnu4jUCQIMSCBDIkQUEQAUIIADhUJEbR4IUMOFGjw4TAIIuCDBAqFcBui4+ 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 EAA7\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

	// closing boundary
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[req setHTTPBody:postBody];
	
	//NSLog(@"postBody: %.*s", [postBody length], [postBody bytes]);

	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:req delegate:self];
	if(theConnection)
	{
		//NSLog(@"Connection success");
		//receivedData = [[NSMutableData data] retain];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		[theConnection retain];
	}
	else 
	{
		NSLog(@"Connection failed");
	}
	
	//NSLog(@"Camera.postImage: posting image to %@.", [url absoluteString]);  //, [error localizedDescription]

//  NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
//	NSString * resultStr =  [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
}

- (void) postLastPickedImage:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	[self postImage:nil withFilename:[options valueForKey:@"filename"] toUrl:[NSURL URLWithString:[options valueForKey:@"url"]]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //[receivedData release];
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	
	//NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	//NSLog(@"connectionDidFinishLoading.  receivedData: %.*s", [receivedData length], [receivedData bytes]);
	
    // release the connection, and the data object
    [connection release];
    //[receivedData release];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) dealloc
{
	if (pickerController) {
		[pickerController release];
	}
	
	[super dealloc];
}

@end


@implementation CameraPicker

@synthesize quality;
@synthesize successCallback;
@synthesize errorCallback;

- (void) dealloc
{
	if (successCallback) {
		[successCallback release];
	}
	if (errorCallback) {
		[errorCallback release];
	}
	
	[super dealloc];
}

@end
