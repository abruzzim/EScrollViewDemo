//
//  ViewController.m
//  EScrollView
//
//  Created by abruzzim on 4/8/15.
//  Copyright (c) 2015 FWS. All rights reserved.
//

#import "ViewController.h"
#import "EScrollView.h"

@interface ViewController ()
@property (nonatomic, strong) EScrollView *testScrollView;
@end

@implementation ViewController

- (void)viewDidLoad {
    NSLog(@"%%ViewController-I-TRACE, -viewDidLoad called.");
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"worldMap"]];
    // Scale the content to fill the size of the view. Some portion of the content may be clipped to fill the view’s bounds.
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    // Confine subviews to the bounds of the view.
    imageView.clipsToBounds = YES;
    
    self.testScrollView = [[EScrollView alloc] initWithFrame:self.view.bounds];
    self.testScrollView.maximumZoomScale = 2.0;
    self.testScrollView.delegate = self;
    self.testScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.testScrollView.contentSize = imageView.frame.size;
    self.testScrollView.alwaysBounceHorizontal = YES;
    self.testScrollView.alwaysBounceVertical = YES;
    self.testScrollView.stickToBounds = YES;
    [self.testScrollView addViewForZooming:imageView];
    [self.testScrollView scaleToFit];
    [self.view addSubview:self.testScrollView];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    NSLog(@"%%ViewController-I-TRACE, -viewForZoomingInScrollView: called.");
    return self.testScrollView.viewForZooming;
}

// Return all of the interface orientations that the view controller supports.
//
- (NSUInteger)supportedInterfaceOrientations {
    NSLog(@"%%ViewController-I-TRACE, -supportedInterfaceOrientations called.");
    return UIInterfaceOrientationMaskAll;
};

// Return the interface orientation to use when presenting the view controller.
//
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    NSLog(@"%%ViewController-I-TRACE, -preferredInterfaceOrientationForPresentation called.");
    return UIInterfaceOrientationPortrait;
};

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    NSLog(@"%%ViewController-I-TRACE, -shouldAutorotateToInterfaceOrientation: called.");
    return YES;
}
*/

@end
