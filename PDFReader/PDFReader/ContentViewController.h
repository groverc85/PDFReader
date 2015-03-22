//
//  ContentViewController.h
//  PDFReader
//
//  Created by Grover Chen on 30/11/14.
//  Copyright (c) 2014 Grover Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDFScrollView.h"

@class PDFScrollView;

@interface ContentViewController : UIViewController <UIScrollViewDelegate> {
    CGPDFDocumentRef thePDF;
    PDFScrollView *pdfScrollView;
}

-(id)initWithPDF:(CGPDFDocumentRef)pdf;

@property (nonatomic, strong) NSString *page;
@end
