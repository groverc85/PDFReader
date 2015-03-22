//
//  AppDelegate.h
//  PDFReader
//
//  Created by Tom HU on 14-1-2.
//  Copyright (c) 2014年 Tom HU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "PDFReadViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

- (void)handleDocumentOpenURL:(NSURL *)url;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *controller;
@property (nonatomic, assign) CGPDFDocumentRef PDFDocument;

@end
