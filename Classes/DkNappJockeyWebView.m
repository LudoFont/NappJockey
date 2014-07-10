/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "DkNappJockeyWebView.h"

@implementation DkNappJockeyWebView


-(UIWebView*)webview
{
	if (webview==nil)
	{
		// we attach the XHR bridge the first time we need a webview
		webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
		webview.delegate = self;
		webview.opaque = NO;
		webview.backgroundColor = [UIColor whiteColor];
		webview.contentMode = UIViewContentModeRedraw;
		webview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self addSubview:webview];
	}
    
	return webview;
}

-(void)render
{
    ENSURE_UI_THREAD_0_ARGS;
    [self webview];
}

- (id)accessibilityElement
{
	return [self webview];
}


-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    [super frameSizeChanged:frame bounds:bounds];
	
	if (webview!=nil)
	{
		[TiUtils setView:webview positionRect:bounds];
	}
}

- (void)setUrl_:(id)args
{
	RELEASE_TO_NIL(url);
	ENSURE_SINGLE_ARG(args,NSString);
    
	url = [[TiUtils toURL:args proxy:(TiProxy*)self.proxy] retain];
    
    if(debug){
        NSLog(@"[NappJockey] setting url: %@", [url absoluteString]);
    }
    
	// load
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [webview loadRequest:request];
}

- (void)setDebug_:(id)args
{
	debug = [TiUtils boolValue:args];
}


- (void)sendJockeyData:(id)args
{
    if(debug){
        NSLog(@"[NappJockey] sending Data Event: %@", [args objectAtIndex:0]);
    }
    NSDictionary *payload = @{@"data": [args objectAtIndex:1]};
    [Jockey send:[TiUtils stringValue:[args objectAtIndex:0]] withPayload:[args objectAtIndex:1] toWebView:[self webview]];
}


#pragma mark WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if(debug){
        NSLog(@"[NappJockey] shouldStartLoadWithRequest url: %@", [[request URL] absoluteString]);
    }
    
    // USING JOCKEY
    if ( [[[request URL] scheme] isEqualToString:@"jockey"] )
    {
        NSString *query = [[request URL] query];
        NSString *jsonString = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error: &error];
        
        NSString *eventName = [JSON objectForKey:@"type"];
        
        // send event
        if ([self.proxy _hasListeners:eventName]) {
            if(debug){
                NSLog(@"[NappJockey] Receiving Event name: %@", eventName);
            }
            
            NSDictionary *event = @{ @"payload": [JSON objectForKey:@"payload"] };
            [self.proxy fireEvent:eventName withObject:event];
        } else {
            if(debug){
                NSLog(@"[NappJockey] [ERROR] No Event Found for: %@", eventName);
            }
        }
        return NO;
    }
    
    if(debug){
        NSLog(@"[NappJockey] No jockey event - fallback");
    }
    
	//return [Jockey webView:[self webview] withUrl:[request URL]];
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

/*
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    [url release];
    url = [[[webview request] URL] retain];
    NSString* urlAbs = [url absoluteString];
    [[self proxy] replaceValue:urlAbs forKey:@"url" notification:NO];
    
    if ([self.proxy _hasListeners:@"load"]) {
        NSDictionary *event = url == nil ? nil : [NSDictionary dictionaryWithObject:[self url] forKey:@"url"];
        [self.proxy fireEvent:@"load" withObject:event];
        
    }
    [webview setNeedsDisplay];
   //TiUIWebViewProxy * ourProxy = (TiUIWebViewProxy *)[self proxy];
   // [ourProxy webviewDidFinishLoad];
}

*/


@end