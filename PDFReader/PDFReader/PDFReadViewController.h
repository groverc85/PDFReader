//
//  PDFReadViewController.h
//  PDFReader
//
//  Created by Grover Chen on 30/11/14.
//  Copyright (c) 2014 Grover Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class ContentViewController;

@interface PDFReadViewController : UIViewController<UIPageViewControllerDelegate, UIPageViewControllerDataSource> {
    UIPageViewController  *thePageViewController;
    ContentViewController *contentViewController;
    NSMutableArray        *modelArray;
    CGPDFDocumentRef      PDFDocument;
    int currentIndex;
    int totalPages;
    bool flag;
}

-(id)initWithPDFAtPath:(NSString *)path;

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (nonatomic, strong) UILabel              *myNavigationTitle;
@end
