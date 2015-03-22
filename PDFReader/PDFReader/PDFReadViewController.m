//
//  PDFReadViewController.m
//  PDFReader
//
//  Created by Grover Chen on 30/11/14.
//  Copyright (c) 2014 Grover Chen. All rights reserved.
//

#import "PDFReadViewController.h"
#import "ContentViewController.h"

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

@interface PDFReadViewController ()

@end

@implementation PDFReadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithPDFAtPath:(NSString *)path
{
    NSURL *pdfUrl = [NSURL fileURLWithPath:path];
    PDFDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfUrl);
    totalPages = (int)CGPDFDocumentGetNumberOfPages(PDFDocument);
    self = [super initWithNibName:nil bundle:nil];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //modelArray holds the page numbers
    modelArray = [[NSMutableArray alloc] init];
    
    for (int index = 1; index <= totalPages; index++) {
        [modelArray addObject:[NSString stringWithFormat:@"%i", index]];
    }
    
    thePageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation: UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    thePageViewController.delegate = self;
    thePageViewController.dataSource = self;
    thePageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    contentViewController = [[ContentViewController alloc] initWithPDF:PDFDocument];
    contentViewController.page = [modelArray objectAtIndex:0];
    contentViewController.edgesForExtendedLayout = UIRectEdgeAll;
    contentViewController.extendedLayoutIncludesOpaqueBars = YES;
    NSArray *viewControllers = [NSArray arrayWithObject:contentViewController];
    [thePageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    [self addChildViewController:thePageViewController];
    [self.view addSubview:thePageViewController.view];
    thePageViewController.view.frame = CGRectMake(0, IS_GREATER_IOS_7?20+44:44, self.view.frame.size.width, SCREENHEIGHT-24);
    [thePageViewController didMoveToParentViewController:self];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    // customer Navigation Bar
    UIView *navigationBar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, IS_GREATER_IOS_7?64:44)];
    [self.view addSubview:navigationBar];
    [navigationBar setBackgroundColor:[UIColor grayColor]];
    
    _myNavigationTitle = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 320, IS_GREATER_IOS_7?64:44)];
    [_myNavigationTitle setTextAlignment:NSTextAlignmentCenter];
    _myNavigationTitle.backgroundColor=[UIColor blackColor];
    [self.view addSubview:_myNavigationTitle];
    
    
    UILabel *PDFlabel = [[UILabel alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-44, IS_GREATER_IOS_7?20:0, 100, 44)];
    PDFlabel.textColor = [UIColor whiteColor];
    [PDFlabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:17.0]];
    PDFlabel.userInteractionEnabled = NO;
    PDFlabel.text = @"PDF Reader";
    [self.view addSubview:PDFlabel];
    
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(0, IS_GREATER_IOS_7?20:0, 44, 44)];
    [backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    UIImage *btnImage = [UIImage imageNamed:@"back.png"];
    [backButton setImage:btnImage forState:UIControlStateNormal];
    
    UIButton *convertButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-44, IS_GREATER_IOS_7?20:0, 44, 44)];
    [convertButton addTarget:self action:@selector(convert:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:convertButton];
    UIImage *cvtImage = [UIImage imageNamed:@"zoomin.png"];
    [convertButton setImage:cvtImage forState:UIControlStateNormal];
}

- (void)updatePDFView:(BOOL)Flag
{
    if (Flag){
        //UIView to UIImage
        CGSize s = thePageViewController.view.bounds.size;
        UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
        [thePageViewController.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage*inputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // 1. Get the raw pixels of the image
        UInt32 * inputPixels;
        
        CGImageRef inputCGImage = [inputImage CGImage];
        NSUInteger inputWidth = CGImageGetWidth(inputCGImage);
        NSUInteger inputHeight = CGImageGetHeight(inputCGImage);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        NSUInteger bytesPerPixel = 4;
        NSUInteger bitsPerComponent = 8;
        
        NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth;
        
        inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
        
        CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                     bitsPerComponent, inputBytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        
        CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputCGImage);
        
        // 3. decide empty row
        NSUInteger totalValue;
        NSUInteger left = 0;
        NSUInteger right = 0;
        NSUInteger top = 0;
        NSUInteger down = 0;
        printf("%lu\n",(unsigned long)inputWidth);
        printf("%lu\n",(unsigned long)inputHeight);
        for (NSUInteger i = 0; i < inputWidth; i++)
        {
            totalValue = 0;
            for (NSUInteger j = 0; j < inputHeight; j++)
            {
                
                UInt32 * currentPixel = inputPixels + (j * inputWidth) + i;
                UInt32 color = *currentPixel;
                
                // Average of RGB = greyscale
                UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
                if (averageColor != 255)
                    totalValue++;
            }
            if (left == 0 && totalValue > 10)
            {
                left = i;
            }
            if (left != 0 && totalValue < 10)
            {
                right = i - 1;
                if ((right - left + 1) % 2 == 1)    right += 1;
                break;
            }
        }
        
//        NSUInteger before = 0;
        //decide top
        for (NSUInteger j = 0; j < inputHeight; j++)
        {
            totalValue = 0;
            for (NSUInteger i = 0; i < inputWidth; i++)
            {
                UInt32 * currentPixel = inputPixels + (j * inputWidth) + i;
                UInt32 color = *currentPixel;
                
                // Average of RGB = greyscale
                UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
                if (averageColor != 255 && averageColor != 0)
                    totalValue++;
            }
            if (top == 0 && totalValue > 2)
            {
                top = j;
                //printf("top = %lu\n",(unsigned long)top);
//                before = top;
                break;
            }
            
        }
        //decide down
        printf("inputHeight: %lu\n",inputHeight);
        for (NSUInteger j = inputHeight - 1; j > 0; j--)
        {
            totalValue = 0;
            UInt32 averageColor;
            for (NSUInteger i = 0; i < inputWidth; i++)
            {
                UInt32 * currentPixel = inputPixels + (j * inputWidth) + i;
                UInt32 color = *currentPixel;
                
                // Average of RGB = greyscale
                averageColor = (R(color) + G(color) + B(color)) / 3.0;
                if (averageColor != 255)
                    totalValue++;
            }
            if (totalValue > 2)
            {
                down = j;
                break;
            }
            
        }
        if (down % 2 == 0)
            down++;
//        printf("top: %lu\n",top);
//        printf("down: %lu\n",down);
//        printf("left: %lu\n",left);
//        printf("right: %lu\n",right);
        //top = 142;
        //down = 601;
        NSUInteger bytesPerRow2 = bytesPerPixel * (right - left + 1);
        UInt32 * Pixels2 = (UInt32 *)calloc((right - left + 1) * (down - top + 1), sizeof(UInt32));
        //        CGContextRef context2 = CGBitmapContextCreate(Pixels2, (right - left +1), (down - top + 1),bitsPerComponent, bytesPerRow2, colorSpace,kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

        for (NSUInteger j = top; j < down + 1; j++)
        {
            for (NSUInteger i = left; i < right + 1; i++)  //“‘‘≠ÕºŒ™ª˘◊º
            {
                UInt32 *newPixel = Pixels2 + (right + 1 - left)*j + i - left;
                UInt32 *oldPixel = inputPixels + (j * inputWidth) + i;
                *newPixel = *oldPixel;
            }
        }
        
        NSUInteger newHeight = down - top + 1;
        NSUInteger newWidth = right - left + 1;
        //        NSUInteger beforePoint = 0;
        //        NSUInteger afterPoint = 0;
        NSUInteger offset = 0;

        UInt32 *Pixels3 = (UInt32 *)calloc((right - left + 1) * (down - top + 1), sizeof(UInt32));
        CGContextRef context3 = CGBitmapContextCreate(Pixels3, (right - left +1)/2, (down - top + 1)*2, bitsPerComponent, bytesPerRow2/2, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        //        bool isWhite = 0;
        
        for (NSUInteger j = 0; j < newHeight; j++)
        {
            totalValue = 0;
            for (NSUInteger i = 0; i < newWidth; i++)
            {
                UInt32 * currentPixel = Pixels2 + (j * inputWidth) + i;
                UInt32 color = *currentPixel;
                UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
                if (averageColor < 253 && averageColor != 0)
                    totalValue++;
                //printf("%d ",averageColor);
            }
            
            
            if (totalValue > 2)
            {
                for (NSUInteger m = j-3; m < j + 27; m++)
                {
                    for (NSUInteger n = 0; n < newWidth/2; n++)
                    {
                        UInt32 *newPixel = Pixels3 + offset;
                        UInt32 *oldPixel = Pixels2 + m*newWidth + n;
                        *newPixel = *oldPixel;
                        offset++;
                        //printf("%lu ",offset);
                    }
                }
                
                for (NSUInteger m = j-3; m < j + 27; m++)
                {
                    for (NSUInteger n = newWidth/2; n < newWidth; n++)
                    {
                        UInt32 *newPixel = Pixels3 + offset;
                        UInt32 *oldPixel = Pixels2 + m*newWidth + n;
                        *newPixel = *oldPixel;
                        offset++;
                        //printf("%lu ",offset);
                    }
                }
                j += 27;
            }
        }
        // 4. Create a new UIImage
        CGImageRef newCGImage = CGBitmapContextCreateImage(context3);
        UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
        
        //UIImage to UIView
        UIImageView *myImageView=[[UIImageView alloc]initWithImage:processedImage];
        
        thePageViewController.view = myImageView;
        
        [self addChildViewController:thePageViewController];
        [self.view addSubview:thePageViewController.view];
        thePageViewController.view.frame = CGRectMake(0, IS_GREATER_IOS_7?20+44:44, self.view.frame.size.width, SCREENHEIGHT-24);
        [thePageViewController didMoveToParentViewController:self];
        self.view.backgroundColor = [UIColor whiteColor];
        
        CFRelease(newCGImage);
        CGContextRelease(context3);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);

    }
    else{
        contentViewController = [[ContentViewController alloc] initWithPDF:PDFDocument];
        contentViewController.page = [modelArray objectAtIndex:currentIndex+1];
        contentViewController.edgesForExtendedLayout = UIRectEdgeAll;
        contentViewController.extendedLayoutIncludesOpaqueBars = YES;
        NSArray *viewControllers = [NSArray arrayWithObject:contentViewController];
        [thePageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        [self addChildViewController:thePageViewController];
        [self.view addSubview:thePageViewController.view];
        thePageViewController.view.frame = CGRectMake(0, IS_GREATER_IOS_7?20+44:44, self.view.frame.size.width, SCREENHEIGHT-24);
        [thePageViewController didMoveToParentViewController:self];
        self.view.backgroundColor = [UIColor whiteColor];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

//通过 thePageViewController.view 可以获得当前的PDF页，类型是UIView，函数的话可以同样的创建一个新的页面，具体可见上面标注的参考部分。
- (IBAction)convert:(id)sender
{
    flag = !flag;
//    [self viewDidLoad];
    [self updatePDFView:flag];
}

- (IBAction)back:(id)sender
{
    if (![self.presentedViewController isBeingDismissed]) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

#pragma mark - UIPageViewControllerDataSource Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    contentViewController = [[ContentViewController alloc] initWithPDF:PDFDocument];
    currentIndex = (int)[modelArray indexOfObject:[(ContentViewController *)viewController page]];
    if (currentIndex == 0) {
        return nil;
    }
    contentViewController.page = [modelArray objectAtIndex:currentIndex - 1];
    
    return contentViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    
    contentViewController = [[ContentViewController alloc] initWithPDF:PDFDocument];
    
    //get the current page
    currentIndex = (int) [modelArray indexOfObject:[(ContentViewController *)viewController page]];
    
    //detect if last page
    //remember that in an array, the first index is 0
    //so if there are three pages, the array will contain the following pages: 0, 1, 2
    //page 2 is the last page, so 3 - 1 = 2 (totalPages - 1 = last page)
    if (currentIndex == totalPages - 1) {
        return nil;
    }
    contentViewController.page = [modelArray objectAtIndex:currentIndex + 1];
    
    return contentViewController;
}

#pragma mark - UIPageViewControllerDelegate Methods

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    UIViewController *currentViewController = [thePageViewController.viewControllers objectAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:currentViewController];
    [thePageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    thePageViewController.doubleSided = NO;
    
    return UIPageViewControllerSpineLocationMin;
}
@end
