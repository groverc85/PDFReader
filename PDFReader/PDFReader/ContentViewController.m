//
//  ContentViewController.m
//  PDFReader
//
//  Created by Grover Chen on 30/11/14.
//  Copyright (c) 2014 Grover Chen. All rights reserved.
//

#import "ContentViewController.h"

@interface ContentViewController ()

@end

@implementation ContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithPDF:(CGPDFDocumentRef)pdf {
    thePDF = pdf;
    self = [super initWithNibName:nil bundle:nil];
    return self;
}

- (void)panMove:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGPoint finalpoint = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y+ translation.y);
    
    //limit the boundary
    if ((gestureRecognizer.view.frame.origin.x>0 && translation.x > 0) || (gestureRecognizer.view.frame.origin.x + gestureRecognizer.view.frame.size.width<=self.view.frame.size.width && translation.x < 0))
        finalpoint.x = gestureRecognizer.view.center.x;
    
    if ((gestureRecognizer.view.frame.origin.y>0 && translation.y > 0) || (gestureRecognizer.view.frame.origin.y + gestureRecognizer.view.frame.size.height<=self.view.frame.size.height && translation.y < 0))
        finalpoint.y = gestureRecognizer.view.center.y;
    
    //set final position
    gestureRecognizer.view.center = finalpoint;
    [gestureRecognizer setTranslation:CGPointZero inView:self.view];
}

- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
    CGFloat lastScale = 1.0;
    if([pinchRecognizer state] == UIGestureRecognizerStateBegan) {
        // Reset the last scale, necessary if there are multiple objects with different scales
        lastScale = [pinchRecognizer scale];
    }
    
    if ([pinchRecognizer state] == UIGestureRecognizerStateBegan ||
        [pinchRecognizer state] == UIGestureRecognizerStateChanged) {
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panMove:)];
        [pdfScrollView addGestureRecognizer:panGesture];
        
        CGFloat currentScale = [[[pinchRecognizer view].layer valueForKeyPath:@"transform.scale"] floatValue];
        
        // Constants to adjust the max/min values of zoom
        const CGFloat kMaxScale = 2.0;
        const CGFloat kMinScale = 1.0;
        
        CGFloat newScale = 1 -  (lastScale - [pinchRecognizer scale]);
        newScale = MIN(newScale, kMaxScale / currentScale);
        newScale = MAX(newScale, kMinScale / currentScale);
        CGAffineTransform transform = CGAffineTransformScale([[pinchRecognizer view] transform], newScale, newScale);
        [pinchRecognizer view].transform = transform;
        
        [pinchRecognizer setScale:1.0];
        
//        lastScale = [pinchRecognizer scale];  // Store the previous scale factor for the next pinch gesture call
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    CGPDFPageRef PDFPage = CGPDFDocumentGetPage(thePDF, [_page intValue]);
    
    pdfScrollView = [[PDFScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SCREENHEIGHT)];
    [pdfScrollView setPDFPage:PDFPage];
    [self.view addSubview:pdfScrollView];
    
    //self.view.backgroundColor = [UIColor underPageBackgroundColor];
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    pdfScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchDetected:)];
    [pdfScrollView addGestureRecognizer:pinchRecognizer];
}
@end
