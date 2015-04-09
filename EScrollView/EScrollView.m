//
//  EScrollView.m
//  EScrollView
//
//  Created by abruzzim on 4/8/15.
//  Copyright (c) 2015 FWS. All rights reserved.
//

#import "EScrollView.h"

@interface EScrollView ()

@property (nonatomic, assign) CGSize prevBoundsSize;     // A structure that contains width and height values.
@property (nonatomic, assign) CGPoint prevContentOffset; // A structure that contains a point in a 2D coordinate system.
@property (nonatomic, strong, readwrite) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong, readwrite) UIView *viewForZooming;

@end

@implementation EScrollView

- (id)initWithFrame:(CGRect)frame {
    NSLog(@"%%EScrollView-I-TRACE, -initWithFrame: called.");
    self = [super initWithFrame:frame];
    if (self) {
        [self performInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"%%EScrollView-I-TRACE, -initWithCoder: called.");
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self performInitialization];
    }
    return self;
}

- (void)performInitialization {
    /**
     * Custom initializer.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -performInitialization called.");
    
    // Set the prevBoundSize to the initial bounds so that the first time layoutSubviews is called it won't perform any contentOffset adjustments.
    self.prevBoundsSize           = self.bounds.size;   // The bounds rectangle, which describes the view’s location and size in its own coordinate system.
    self.prevContentOffset        = self.contentOffset; // The point at which the origin of the content view is offset from the origin of the scroll view.
    
    self.fitOnSizeChange          = NO;  // Keep the content point, displayed in the center of scrollView bounds, in the center after an interface orientation change.
    self.upscaleToFitOnSizeChange = YES; // Scale the content to fit to scrollView bounds, but only if they are bigger than content.
    self.stickToBounds            = NO;  // Keep content bounds center point in center.
    self.centerZoomingView        = YES; // Center scrollView content in the center of its bounds.
    
    /**
     * Add a content zoom double-tap-gesture-recognizer.
     */
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_doubleTapped:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:self.doubleTapGestureRecognizer];
}

- (void)setContentSize:(CGSize)contentSize {
    /**
     * Set the size of the content view in points.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -setContentSize: called.");
    
    [super setContentSize:contentSize];
    [self _centerScrollViewContent];
}

- (void)setZoomScale:(CGFloat)zoomScale {
    /**
     * A floating-point value that specifies the current scale factor applied to 
     * the scroll view’s content.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -setZoomScale: called.");
    
    // A floating-point value that specifies the current scale factor applied to the scroll view’s content.
    [super setZoomScale:zoomScale];
    // Bug fix: On iPhone 6+ iOS8, after setting zoomScale content, the contentSize becomes slightly bigger than bounds (e.g. 0.00001)
    self.contentSize = CGSizeMake(floorf(self.contentSize.width), floorf(self.contentSize.height));
}

- (void)scaleToFit {
    /**
     * Set the current scale factor applied to the scroll view’s content to the minimum.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -scaleToFit called.");
    
    // Check if the delegate of the scroll-view object implements or inherits a method
    // that can respond to the viewForZoomingInScrollView: message.
    if (![self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return;
    }
    // Set the minimum scale factor that can be applied to the scroll view’s content.
    [self _setMinimumZoomScaleToFit];
    // Set the current scale factor applied to the scroll view’s content to the minimum.
    self.zoomScale = self.minimumZoomScale;
}

- (void)addViewForZooming:(UIView *)view {
    /**
     * Convenient method to add a view for zooming. The added view is available as 
     * viewForZooming property. Adding new view for zooming will remove the previously 
     * added one.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -addViewForZooming: called.");
    
    // The view that was added by addViewForZooming: method
    if (self.viewForZooming) {
        // Unlinks the view from its superview and its window, and removes it from the responder chain.
        [self.viewForZooming removeFromSuperview];
    }
    //
    self.viewForZooming = view;
    //
    [self addSubview:self.viewForZooming];
}

- (void)layoutSubviews {
    /**
     * Lays out subviews. The default implementation uses any constraints you have set 
     * to determine the size and position of any subviews.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -layoutSubviews called.");
    
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.prevBoundsSize, self.bounds.size)) {
        if (self.fitOnSizeChange) {
            [self scaleToFit];
        } else {
            [self _adjustContentOffset];
        }
        self.prevBoundsSize = self.bounds.size;
    }
    self.prevContentOffset = self.contentOffset;
    
    [self _centerScrollViewContent];
}

- (void)_adjustContentOffset {
    /**
     * .
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -_adjustContentOffset called.");

    if ([self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        
        UIView *zoomView = [self.delegate viewForZoomingInScrollView:self];
        
        // Using contentOffset and bounds values before the bounds were changed,
        // find the visible center point in the unscaled coordinate space of the zooming view.
        //
        CGPoint prevCenterPoint = (CGPoint) {
            .x = (self.prevContentOffset.x + roundf(self.prevBoundsSize.width  / 2) - zoomView.frame.origin.x) / self.zoomScale,
            .y = (self.prevContentOffset.y + roundf(self.prevBoundsSize.height / 2) - zoomView.frame.origin.y) / self.zoomScale,
        };
        
        if (self.stickToBounds) {
            // If the content bounds is to be stuck to the scrollView edges...
            //
            if (self.contentSize.width > self.prevBoundsSize.width) {
                if (self.prevContentOffset.x == 0) {
                    prevCenterPoint.x = 0;
                } else if (self.prevContentOffset.x + self.prevBoundsSize.width == roundf(self.contentSize.width)) {
                    prevCenterPoint.x = zoomView.bounds.size.width;
                }
            }
            //
            if (self.contentSize.height > self.prevBoundsSize.height) {
                if (self.prevContentOffset.y == 0) {
                    prevCenterPoint.y = 0;
                } else if (self.prevContentOffset.y + self.prevBoundsSize.height == roundf(self.contentSize.height)) {
                    prevCenterPoint.y = zoomView.bounds.size.height;
                }
            }
        }
        
        // If the size of the scrollView was changed such that the minimumZoomScale is increased...
        //
        if (self.upscaleToFitOnSizeChange) {
            [self _increaseScaleIfNeeded];
        }
        
        // Calculate new contentOffset using the previously calculated center point and the new contentOffset and bounds values.
        //
        CGPoint contentOffset = CGPointMake(0.0, 0.0);
        CGRect frame = zoomView.frame;
        
        if (self.contentSize.width > self.bounds.size.width) {
            frame.origin.x = 0;
            contentOffset.x = prevCenterPoint.x * self.zoomScale - roundf(self.bounds.size.width / 2);
            if (contentOffset.x < 0) {
                contentOffset.x = 0;
            } else if (contentOffset.x > self.contentSize.width - self.bounds.size.width) {
                contentOffset.x = self.contentSize.width - self.bounds.size.width;
            }
        }
        
        if (self.contentSize.height > self.bounds.size.height) {
            frame.origin.y = 0;
            contentOffset.y = prevCenterPoint.y * self.zoomScale - roundf(self.bounds.size.height / 2);
            if (contentOffset.y < 0) {
                contentOffset.y = 0;
            } else if (contentOffset.y > self.contentSize.height - self.bounds.size.height) {
                contentOffset.y = self.contentSize.height - self.bounds.size.height;
            }
        }
        
        self.contentOffset = contentOffset;
        zoomView.frame = frame;
        
    }
}

- (void)_setMinimumZoomScaleToFit {
    /**
     * Determine the minimum scale factor that can be applied to the scroll view's content.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -_setMinimumZoomScaleToFit called.");

    // Asks the delegate for the view to scale when zooming is about to occur in the scroll view.
    //
    UIView *zoomView = [self.delegate viewForZoomingInScrollView:self];
    CGSize zoomViewSize = zoomView.bounds.size;
    CGSize scrollViewSize = self.bounds.size;
    
    CGFloat scaleToFit = fminf(scrollViewSize.width / zoomViewSize.width, scrollViewSize.height / zoomViewSize.height);
    if (scaleToFit > 1.0) {
        scaleToFit = 1.0;
    }
    // Set the minimum scale factor that can be applied to the scroll view’s content.
    //
    self.minimumZoomScale = scaleToFit;
}

- (void)_centerScrollViewContent {
    /**
     * .
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -_centerScrollViewContent called.");

    if (self.centerZoomingView && [self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        
        // Asks the delegate for the view to scale when zooming is about to occur in the scroll view.
        UIView *zoomView = [self.delegate viewForZoomingInScrollView:self];
        // Get he frame rectangle, which describes the zoomView’s location and size in its superview’s coordinate system.
        CGRect frame = zoomView.frame;
        //
        if (self.contentSize.width < self.bounds.size.width) {
            frame.origin.x = roundf((self.bounds.size.width - self.contentSize.width) / 2);
        } else {
            frame.origin.x = 0;
        }
        //
        if (self.contentSize.height < self.bounds.size.height) {
            frame.origin.y = roundf((self.bounds.size.height - self.contentSize.height) / 2);
        } else {
            frame.origin.y = 0;
        }
        //
        zoomView.frame = frame;
    }
}

- (void)_increaseScaleIfNeeded {
    /**
     * Increases the zoom scale if it is less then the minimum.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -_increaseScaleIfNeeded called.");
    
    [self _setMinimumZoomScaleToFit];
    if (self.zoomScale < self.minimumZoomScale) {
        // If the current scale factor applied to the scroll view’s content
        // is less than the minimum scale factor that can be applied to the
        // scroll view’s content;
        self.zoomScale = self.minimumZoomScale;
        // set the current scale factor to the minimum scale factor.
    }
}

- (void)_doubleTapped:(UIGestureRecognizer *)gestureRecognizer {
    /**
     * Handle zooming as a result of double tapping.
     */
    
    NSLog(@"%%EScrollView-I-TRACE, -_doubleTapped: called.");
    
    if ([self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        
        UIView *zoomView = [self.delegate viewForZoomingInScrollView:self];
        
        if (self.zoomScale == self.minimumZoomScale) {
            
            CGFloat newScale = self.maximumZoomScale;
            CGPoint centerPoint = [gestureRecognizer locationInView:zoomView];
            CGRect zoomRect = [self _zoomRectInView:self forScale:newScale withCenter:centerPoint];
            //When the user double-taps on the scrollView while it is zoomed out then zoom in.
            //
            [self zoomToRect:zoomRect animated:YES];
        } else {
            // When the user double-taps on the scrollView while it is zoomed in then zoom out.
            //
            [self setZoomScale:self.minimumZoomScale animated:YES];
        }
    }
}

- (CGRect)_zoomRectInView:(UIView *)view forScale:(CGFloat)scale withCenter:(CGPoint)center {
    /**
     * .
     */
    
    CGRect zoomRect;
    
    //
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    //
    zoomRect.size.width = view.bounds.size.width /scale;
    zoomRect.size.height = view.bounds.size.height / scale;
    
    return zoomRect;
}

@end
