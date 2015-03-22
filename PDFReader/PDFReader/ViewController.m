//
//  ViewController.m
//  PDFReader
//
//  Created by Grover Chen on 30/11/14.
//  Copyright (c) 2014 Grover Chen. All rights reserved.
//

#import "ViewController.h"
#import "PDFReadViewController.h"

@interface ViewController ()

@end

@implementation ViewController

UIDocumentInteractionController *documentController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)OpenPDF:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PDF" ofType:@"pdf"];
    
    PDFReadViewController *page = [[PDFReadViewController alloc] initWithPDFAtPath:path];
    [self presentViewController:page animated:YES completion:NULL];

}

@end
