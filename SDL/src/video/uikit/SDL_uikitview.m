/*
 SDL - Simple DirectMedia Layer
 Copyright (C) 1997-2009 Sam Lantinga
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 
 Sam Lantinga
 slouken@libsdl.org
 */

#import "SDL_uikitview.h"

#if SDL_IPHONE_KEYBOARD
#import "SDL_keyboard_c.h"
#import "keyinfotable.h"
#import "SDL_uikitappdelegate.h"
#import "SDL_uikitwindow.h"
#import "UIExtendedTextField.h"
#endif

#include "SDL_compat.h"

#ifdef IPHONEOS
// For calling
#import "SDL_keyboard_c.h"
#import "keyinfotable.h"
void SDL_init_keyboard()
{
    SDL_Keyboard keyboard;
	SDL_zero(keyboard);
	SDL_AddKeyboard(&keyboard, 0);
	SDLKey keymap[SDL_NUM_SCANCODES];
	SDL_GetDefaultKeymap(keymap);
	SDL_SetKeymap(0, 0, keymap, SDL_NUM_SCANCODES);
}
#endif

@implementation SDL_uikitview
#ifdef IPHONEOS
@synthesize mouseHoldDelegate;
#endif

- (void)dealloc {
#if SDL_IPHONE_KEYBOARD
	SDL_DelKeyboard(0);
	[textField release];
#endif
	[super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    
	self = [super initWithFrame: frame];
	
#if SDL_IPHONE_KEYBOARD
	[self initializeKeyboard];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
#endif
    
    [self setupGestureRecognizers];
    
	int i;
	for (i=0; i<MAX_SIMULTANEOUS_TOUCHES; i++) {
        mice[i].id = i;
		mice[i].driverdata = NULL;
		SDL_AddMouse(&mice[i], "Mouse", 0, 0, 1);
	}
    
	self.multipleTouchEnabled = YES;
    
	return self;
    
}

#ifdef IPHONEOS

- (void)sendMouseEvent:(int)index left:(BOOL)isLeft down:(BOOL)isDown
{
    if (index >= 0 && index < SDL_GetNumMice()) {
        SDL_SendMouseButton(index,
                            isDown?SDL_PRESSED:SDL_RELEASED,
                            isLeft?SDL_BUTTON_LEFT:SDL_BUTTON_RIGHT);
    }
}

- (void)keyboardWillShow:(id)sender
{
    // we never want this keyboard to show
    // the uitextfield is our proxy for receiving external keyboard input
    [self hideKeyboard];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
	
	self.multipleTouchEnabled = YES;
    
	return self;
}
-(CGFloat) distanceBetween: (CGPoint) point1 and: (CGPoint)point2
{
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy );
}

-(float) getMouseScale
{
    float mouseSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"mouse_speed"];
    if (mouseSpeed == 0) mouseSpeed=0.5;
    return 1+2*mouseSpeed;
}

-(bool) getMouseRelative
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"mouse_relative_enabled"];
}

-(void)holdButton:(NSNumber*)mouseIndex
{
    int i = [mouseIndex intValue];
    // We make sure the mouse is not detached
    // In fact, it should not be NULL according to our logic
    // Play safer here.
    if (mice[i].driverdata!=NULL) {
        if (extmice[i].mouseHold==MOUSE_HOLD_WAIT) {
            SDL_SendMouseButton(i, SDL_PRESSED,
                                extmice[i].leftHold?SDL_BUTTON_LEFT:SDL_BUTTON_RIGHT);
            extmice[i].mouseHold = MOUSE_HOLD_YES;
            if (mouseHoldDelegate) {
                [mouseHoldDelegate onHold:extmice[i].ptOrig];
            }
        }
    }
}

-(void)cancelHold
{
    // We could use cancelPreviousPerformRequestsWithTarget,
    //
    //  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(holdButton:) object:(index)];
    //
    // but here for simplicity
    for (int i = 0; i < MAX_SIMULTANEOUS_TOUCHES; i++) {
        if (mice[i].driverdata !=NULL) {
            if (extmice[i].mouseHold==MOUSE_HOLD_WAIT) {
                extmice[i].mouseHold=MOUSE_HOLD_NO;
            }
        }
    }
}

#endif

- (void)setupGestureRecognizers {
    {
        UIPanGestureRecognizer *panOneFinger = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        panOneFinger.maximumNumberOfTouches = 1;
        panOneFinger.delaysTouchesBegan = NO;
        panOneFinger.delaysTouchesEnded = NO;
        panOneFinger.cancelsTouchesInView = YES;
        
        UISwipeGestureRecognizer *swipeRightOneFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
        swipeRightOneFinger.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRightOneFinger.numberOfTouchesRequired = 1;
        swipeRightOneFinger.delaysTouchesBegan = NO;
        swipeRightOneFinger.delaysTouchesEnded = NO;
        swipeRightOneFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeRightTwoFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
        swipeRightTwoFinger.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRightTwoFinger.numberOfTouchesRequired = 2;
        swipeRightTwoFinger.delaysTouchesBegan = NO;
        swipeRightTwoFinger.delaysTouchesEnded = NO;
        swipeRightTwoFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeLeftOneFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
        swipeLeftOneFinger.direction = UISwipeGestureRecognizerDirectionLeft;
        swipeLeftOneFinger.numberOfTouchesRequired = 1;
        swipeLeftOneFinger.delaysTouchesBegan = NO;
        swipeLeftOneFinger.delaysTouchesEnded = NO;
        swipeLeftOneFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeLeftTwoFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
        swipeLeftTwoFinger.direction = UISwipeGestureRecognizerDirectionLeft;
        swipeLeftTwoFinger.numberOfTouchesRequired = 2;
        swipeLeftTwoFinger.delaysTouchesBegan = NO;
        swipeLeftTwoFinger.delaysTouchesEnded = NO;
        swipeLeftTwoFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeUpOneFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
        swipeUpOneFinger.direction = UISwipeGestureRecognizerDirectionUp;
        swipeUpOneFinger.numberOfTouchesRequired = 1;
        swipeUpOneFinger.delaysTouchesBegan = NO;
        swipeUpOneFinger.delaysTouchesEnded = NO;
        swipeUpOneFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeUpTwoFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
        swipeUpTwoFinger.direction = UISwipeGestureRecognizerDirectionUp;
        swipeUpTwoFinger.numberOfTouchesRequired = 2;
        swipeUpTwoFinger.delaysTouchesBegan = NO;
        swipeUpTwoFinger.delaysTouchesEnded = NO;
        swipeUpTwoFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeDownOneFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
        swipeDownOneFinger.direction = UISwipeGestureRecognizerDirectionDown;
        swipeDownOneFinger.numberOfTouchesRequired = 1;
        swipeDownOneFinger.delaysTouchesBegan = NO;
        swipeDownOneFinger.delaysTouchesEnded = NO;
        swipeDownOneFinger.cancelsTouchesInView = NO;
        
        UISwipeGestureRecognizer *swipeDownTwoFinger = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
        swipeDownTwoFinger.direction = UISwipeGestureRecognizerDirectionDown;
        swipeDownTwoFinger.numberOfTouchesRequired = 2;
        swipeDownTwoFinger.delaysTouchesBegan = NO;
        swipeDownTwoFinger.delaysTouchesEnded = NO;
        swipeDownTwoFinger.cancelsTouchesInView = NO;
/*
        UITapGestureRecognizer *doubleTapTwoFinger = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapTwoFinger.numberOfTapsRequired = 2;
        doubleTapTwoFinger.numberOfTouchesRequired = 2;
        doubleTapTwoFinger.delaysTouchesBegan = NO;
        doubleTapTwoFinger.delaysTouchesEnded = NO;
 */
        UITapGestureRecognizer *singleTapOneFinger = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        singleTapOneFinger.numberOfTapsRequired = 1;
        singleTapOneFinger.numberOfTouchesRequired = 1;
        singleTapOneFinger.delaysTouchesBegan = NO;
        singleTapOneFinger.delaysTouchesEnded = NO;
        singleTapOneFinger.cancelsTouchesInView = NO;
 
        
        UITapGestureRecognizer *singleTapTwoFinger = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        singleTapTwoFinger.numberOfTapsRequired = 1;
        singleTapTwoFinger.numberOfTouchesRequired = 2;
        singleTapTwoFinger.delaysTouchesBegan = NO;
        singleTapTwoFinger.delaysTouchesEnded = NO;
        singleTapTwoFinger.cancelsTouchesInView = NO;
        
        UILongPressGestureRecognizer *singlePressOneFinger = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(singlePress:)];
        singlePressOneFinger.numberOfTapsRequired = 0;
        singlePressOneFinger.numberOfTouchesRequired = 1;
        singlePressOneFinger.allowableMovement = 10;
        singlePressOneFinger.minimumPressDuration = 0.3;
        singlePressOneFinger.delaysTouchesBegan = NO;
        singlePressOneFinger.delaysTouchesEnded = NO;
        singlePressOneFinger.cancelsTouchesInView = YES;
        
        UILongPressGestureRecognizer *singlePressTwoFinger = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(singlePress:)];
        singlePressTwoFinger.numberOfTapsRequired = 0;
        singlePressTwoFinger.numberOfTouchesRequired = 2;
        singlePressTwoFinger.allowableMovement = 5;
        singlePressTwoFinger.minimumPressDuration = 0.3;
        singlePressTwoFinger.delaysTouchesBegan = NO;
        singlePressTwoFinger.delaysTouchesEnded = NO;
        singlePressTwoFinger.cancelsTouchesInView = YES;
        
        [self addGestureRecognizer:panOneFinger];
        [self addGestureRecognizer:swipeRightOneFinger];
        [self addGestureRecognizer:swipeRightTwoFinger];
        [self addGestureRecognizer:swipeLeftOneFinger];
        [self addGestureRecognizer:swipeLeftTwoFinger];
        [self addGestureRecognizer:swipeUpOneFinger];
        [self addGestureRecognizer:swipeUpTwoFinger];
        [self addGestureRecognizer:swipeDownOneFinger];
        [self addGestureRecognizer:swipeDownTwoFinger];
//        [self addGestureRecognizer:doubleTapTwoFinger];
        [self addGestureRecognizer:singleTapOneFinger];
        [self addGestureRecognizer:singleTapTwoFinger];
        [self addGestureRecognizer:singlePressOneFinger];
        [self addGestureRecognizer:singlePressTwoFinger];
        
        [panOneFinger release];
        [swipeRightOneFinger release];
        [swipeRightTwoFinger release];
        [swipeLeftOneFinger release];
        [swipeLeftTwoFinger release];
        [swipeUpOneFinger release];
        [swipeUpTwoFinger release];
        [swipeDownOneFinger release];
        [swipeDownTwoFinger release];
//        [doubleTapTwoFinger release];
        [singleTapOneFinger release];
        [singleTapTwoFinger release];
        [singlePressOneFinger release];
        [singlePressTwoFinger release];
    }
}

CGPoint prevpoint;

- (void)pan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint point = [recognizer locationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if( [self getMouseRelative] )
            prevpoint=point;
        else
            SDL_WarpMouse(point.x, point.y);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if( [self getMouseRelative] )
        {
            float scale = [self getMouseScale];
            SDL_SendMouseMotion(0, 1, (point.x-prevpoint.x) * scale, (point.y-prevpoint.y) * scale, 0);
            prevpoint=point;
        }
        else
            SDL_SendMouseMotion(0, 0, point.x, point.y, 0);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
        return;
}

- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.numberOfTouches == 1)
        return;
    else if (recognizer.numberOfTouches == 2)
        return;
    return;
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.numberOfTouches == 1)
        return;
    else if (recognizer.numberOfTouches == 2)
        return;
    return;
}

- (void)swipeUp:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.numberOfTouches == 1)
        return;
    else if (recognizer.numberOfTouches == 2)
        return;
    return;
}

- (void)swipeDown:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.numberOfTouches == 1)
        return;
    else if (recognizer.numberOfTouches == 2)
        return;
    return;
}

- (void)doubleTap:(UITapGestureRecognizer *)recognizer {
    return;
}

- (void)singleTap:(UITapGestureRecognizer *)recognizer {

    CGPoint point = [recognizer locationInView:self];
    
    if ( ![self getMouseRelative] )
        SDL_WarpMouse(point.x, point.y);
    
    if (recognizer.numberOfTouches == 1)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            SDL_SendMouseButton(0, SDL_PRESSED, SDL_BUTTON_LEFT);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                SDL_SendMouseButton(0, SDL_RELEASED, SDL_BUTTON_LEFT);
            });
        });
    }
    else if (recognizer.numberOfTouches == 2)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            SDL_SendMouseButton(0, SDL_PRESSED, SDL_BUTTON_RIGHT);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                SDL_SendMouseButton(0, SDL_RELEASED, SDL_BUTTON_RIGHT);
            });
        });
    }
    return;
}

- (void)singlePress:(UILongPressGestureRecognizer *)recognizer {

    CGPoint point = [recognizer locationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if( [self getMouseRelative] )
            prevpoint=point;
        else
            SDL_WarpMouse(point.x, point.y);
        
        if (recognizer.numberOfTouches == 1)
            SDL_SendMouseButton(0, SDL_PRESSED, SDL_BUTTON_LEFT);
        else if (recognizer.numberOfTouches == 2)
            SDL_SendMouseButton(0, SDL_PRESSED, SDL_BUTTON_RIGHT);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if( [self getMouseRelative] )
        {
            float scale = [self getMouseScale];
            SDL_SendMouseMotion(0, 1, (point.x-prevpoint.x) * scale, (point.y-prevpoint.y) * scale, 0);
            prevpoint=point;
        }
        else
            SDL_SendMouseMotion(0, 0, point.x, point.y, 0);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        if (recognizer.numberOfTouches == 1)
            SDL_SendMouseButton(0, SDL_RELEASED, SDL_BUTTON_LEFT);
        else if (recognizer.numberOfTouches == 2)
            SDL_SendMouseButton(0, SDL_RELEASED, SDL_BUTTON_RIGHT);
    }
    
}

- (void)doublePress:(UILongPressGestureRecognizer *)recognizer {
    
    CGPoint point = [recognizer locationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if( [self getMouseRelative] )
            prevpoint=point;
        else
            SDL_WarpMouse(point.x, point.y);
        
        SDL_SendMouseButton(0, SDL_PRESSED, SDL_BUTTON_RIGHT);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if( [self getMouseRelative] )
        {
            float scale = [self getMouseScale];
            SDL_SendMouseMotion(0, 1, (point.x-prevpoint.x) * scale, (point.y-prevpoint.y) * scale, 0);
            prevpoint=point;
        }
        else
            SDL_SendMouseMotion(0, 0, point.x, point.y, 0);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
        SDL_SendMouseButton(0, SDL_RELEASED, SDL_BUTTON_RIGHT);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
#ifdef IPHONEOS
    if (SDL_GetNumMice() == 0) {
        int i;
        for (i=0; i<MAX_SIMULTANEOUS_TOUCHES; i++) {
            mice[i].id = i;
            mice[i].driverdata = NULL;
            SDL_AddMouse(&mice[i], "Mouse", 0, 0, 1);
            SDL_SetRelativeMouseMode(i, SDL_FALSE);
        }
    }
#endif
    SDL_SelectMouse(0);
    return;
    
	NSEnumerator *enumerator = [touches objectEnumerator];
	UITouch *touch =(UITouch*)[enumerator nextObject];
	
	/* associate touches with mice, so long as we have slots */
	int i;
	int found = 0;
	for(i=0; touch && i < MAX_SIMULTANEOUS_TOUCHES; i++) {
        
		/* check if this mouse is already tracking a touch */
		if (mice[i].driverdata != NULL) {
			continue;
		}
		/*
         mouse not associated with anything right now,
         associate the touch with this mouse
         */
		found = 1;
		
		/* save old mouse so we can switch back */
		int oldMouse = SDL_SelectMouse(-1);
		
		/* select this slot's mouse */
		SDL_SelectMouse(i);
		CGPoint locationInView = [touch locationInView: self];
		
        SDL_WarpMouse(locationInView.x, locationInView.y);
        
		/* set driver data to touch object, we'll use touch object later */
		mice[i].driverdata = [touch retain];
		
#ifdef IPHONEOS
        extmice[i].ptOrig = locationInView;
        extmice[i].timestamp = touch.timestamp;
        extmice[i].mouseHold=MOUSE_HOLD_NO;
        
        int leftHold = 1; // By default it is a left button hold
        int canHold = 1;  // By default send a hold request
        for (int j = 0; j < MAX_SIMULTANEOUS_TOUCHES; j++) {
            if (j!=i && mice[j].driverdata !=NULL) {
                leftHold=0;
                if (extmice[j].mouseHold==MOUSE_HOLD_YES) // No hold if there is already another onhold
                    canHold=0;
                break;
            }
        }
        
        if (canHold) {
            [self cancelHold]; // Should come first because it will clear hold data
            extmice[i].mouseHold=MOUSE_HOLD_WAIT;
            extmice[i].leftHold = leftHold;
            [self performSelector:@selector(holdButton:)
                       withObject:[NSNumber numberWithInt:i]
                       afterDelay:MOUSE_HOLD_INTERVAL];
        }
#else
        /* send moved event */
		SDL_SendMouseMotion(i, 0, locationInView.x, locationInView.y, 0);
		/* send mouse down event */
		SDL_SendMouseButton(i, SDL_PRESSED, SDL_BUTTON_LEFT);
#endif
		/* re-calibrate relative mouse motion */
		SDL_GetRelativeMouseState(i, NULL, NULL);
		
		/* grab next touch */
		touch = (UITouch*)[enumerator nextObject];
		
		/* switch back to our old mouse */
		SDL_SelectMouse(oldMouse);
		
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    return;
	NSEnumerator *enumerator = [touches objectEnumerator];
	UITouch *touch=nil;
	
	while(touch = (UITouch *)[enumerator nextObject]) {
		/* search for the mouse slot associated with this touch */
		int i, found = NO;
		for (i=0; i<MAX_SIMULTANEOUS_TOUCHES && !found; i++) {
			if (mice[i].driverdata == touch) {
				/* found the mouse associate with the touch */
				[(UITouch*)(mice[i].driverdata) release];
				mice[i].driverdata = NULL;
				/* send mouse up */
#ifdef IPHONEOS
                double interval = touch.timestamp - extmice[i].timestamp;
                
                /* If there is another touch, then this should be a right click*/
                int rightClick=0;
                for (int j = 0; j < MAX_SIMULTANEOUS_TOUCHES; j++) {
                    if (j!=i && mice[j].driverdata!=NULL) {
                        rightClick=1;
                        break;
                    }
                }
                
                if ([touch tapCount] == 2) {
                    if (rightClick) {
                        [self cancelHold];
                    } else if ([mouseHoldDelegate currentRightClickMode] == MouseRightClickWithDoubleTap) {
						rightClick = 1;
					}
                    SDL_SendMouseButton(i, SDL_PRESSED,  !rightClick?SDL_BUTTON_LEFT:SDL_BUTTON_RIGHT);
                    // Must have or won't work
                    [NSThread sleepForTimeInterval:0.01];
                    SDL_SendMouseButton(i, SDL_RELEASED, !rightClick?SDL_BUTTON_LEFT:SDL_BUTTON_RIGHT);
                } else if (interval < TAP_THRESHOLD) {
                    if (rightClick) {
                        [self cancelHold];
                    }
                    SDL_SendMouseButton(i, SDL_PRESSED,  !rightClick?SDL_BUTTON_LEFT:SDL_BUTTON_RIGHT);
                    // Must have or won't work
                    [NSThread sleepForTimeInterval:0.01];
                    SDL_SendMouseButton(i, SDL_RELEASED, !rightClick?SDL_BUTTON_LEFT:SDL_BUTTON_RIGHT);
                } else if (extmice[i].mouseHold==MOUSE_HOLD_YES) {
                    SDL_SendMouseButton(i, SDL_RELEASED, SDL_BUTTON_LEFT);
                }
                
                if (extmice[i].mouseHold == MOUSE_HOLD_WAIT) {
                    [self cancelHold];
                }
                
                if (extmice[i].mouseHold == MOUSE_HOLD_YES) {
                    if (mouseHoldDelegate) {
                        [mouseHoldDelegate cancelHold:extmice[i].ptOrig];
                    }
                }
                
#else
				SDL_SendMouseButton(i, SDL_RELEASED, SDL_BUTTON_LEFT);
#endif
				/* discontinue search for this touch */
				found = YES;
			}
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	/*
     this can happen if the user puts more than 5 touches on the screen
     at once, or perhaps in other circumstances.  Usually (it seems)
     all active touches are canceled.
     */
	[self touchesEnded: touches withEvent: event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    return;
	NSEnumerator *enumerator = [touches objectEnumerator];
	UITouch *touch=nil;
	
	while(touch = (UITouch *)[enumerator nextObject]) {
		/* try to find the mouse associated with this touch */
		int i, found = NO;
		for (i=0; i<MAX_SIMULTANEOUS_TOUCHES && !found; i++) {
			if (mice[i].driverdata == touch) {
				/* found proper mouse */
#ifdef IPHONEOS
                CGPoint locationInView = [touch locationInView: [self superview]];
                CGPoint prevLocation = [touch previousLocationInView: [self superview]];
                float dx = locationInView.x-prevLocation.x;
                float dy = locationInView.y-prevLocation.y;
                float mouseSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"mouse_speed"];
                if (mouseSpeed == 0) mouseSpeed=0.5;
                float scale = 1+2*mouseSpeed;
                CGPoint ptOrig = [self convertPoint:extmice[i].ptOrig toView:[self superview]];
                if (MOUSE_HOLD_NO!=extmice[i].mouseHold
                    && [self distanceBetween:ptOrig and:locationInView] > POSITION_CHANGE_THRESHOLD)
                {
                    if (extmice[i].mouseHold == MOUSE_HOLD_WAIT) {
                        [self cancelHold];
                    } else if (extmice[i].mouseHold == MOUSE_HOLD_YES) {
                        SDL_SendMouseButton(i, SDL_RELEASED, SDL_BUTTON_LEFT);
                        if (mouseHoldDelegate) {
                            [mouseHoldDelegate cancelHold:extmice[i].ptOrig];
                        }
                    }
                    extmice[i].mouseHold=MOUSE_HOLD_NO;
                }
                if (extmice[i].mouseHold==MOUSE_HOLD_NO) {
                    SDL_SendMouseMotion(i, 1, dx*scale, dy*scale, 0);
                }
#else
                CGPoint locationInView = [touch locationInView: self];
				/* send moved event */
				SDL_SendMouseMotion(i, 0, locationInView.x, locationInView.y, 0);
#endif
				/* discontinue search */
				found = YES;
			}
		}
	}
}

/*
 ---- Keyboard related functionality below this line ----
 */
#if SDL_IPHONE_KEYBOARD

/* Is the iPhone virtual keyboard visible onscreen? */
- (BOOL)keyboardVisible {
	return keyboardVisible;
}

/* Set ourselves up as a UITextFieldDelegate */
- (void)initializeKeyboard {
    
	textField = [[[UIExtendedTextField alloc] initWithFrame: CGRectZero] autorelease];
	textField.delegate = self;
	/* placeholder so there is something to delete! */
	textField.text = @" ";
	
	/* set UITextInputTrait properties, mostly to defaults */
	textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	textField.autocorrectionType = UITextAutocorrectionTypeNo;
	textField.enablesReturnKeyAutomatically = NO;
	textField.keyboardAppearance = UIKeyboardAppearanceDefault;
	textField.keyboardType = UIKeyboardTypeDefault;
	textField.returnKeyType = UIReturnKeyDefault;
	textField.secureTextEntry = NO;
	textField.hidden = YES;
    
	keyboardVisible = NO;
	/* add the UITextField (hidden) to our view */
	[self addSubview:textField];
    // Commented the following line to prevent keybaord from coming up at startup
    // [self showKeyboard];
	
	/* create our SDL_Keyboard */
	SDL_Keyboard keyboard;
	SDL_zero(keyboard);
	SDL_AddKeyboard(&keyboard, 0);
	SDLKey keymap[SDL_NUM_SCANCODES];
	SDL_GetDefaultKeymap(keymap);
	SDL_SetKeymap(0, 0, keymap, SDL_NUM_SCANCODES);
}



/* reveal onscreen virtual keyboard */
- (void)showKeyboard {
	keyboardVisible = YES;
	[textField becomeFirstResponder];
}

/* hide onscreen virtual keyboard */
- (void)hideKeyboard {
	keyboardVisible = NO;
	[textField resignFirstResponder];
}

/* UITextFieldDelegate method.  Invoked when user types something. */
- (BOOL)textField:(UITextField *)_textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if ([string length] == 0) {
		/* it wants to replace text with nothing, ie a delete */
		SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_BACKSPACE);
		SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_BACKSPACE);
	}
	else {
		/* go through all the characters in the string we've been sent
         and convert them to key presses */
		int i;
		for (i=0; i<[string length]; i++) {
			
			unichar c = [string characterAtIndex: i];
			
			Uint16 mod = 0;
			SDL_scancode code;
			
			if (c < 127) {
				/* figure out the SDL_scancode and SDL_keymod for this unichar */
				code = unicharToUIKeyInfoTable[c].code;
				mod  = unicharToUIKeyInfoTable[c].mod;
			}
			else {
				/* we only deal with ASCII right now */
				code = SDL_SCANCODE_UNKNOWN;
				mod = 0;
			}
			
			if (mod & KMOD_SHIFT) {
				/* If character uses shift, press shift down */
				SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_LSHIFT);
			}
			/* send a keydown and keyup even for the character */
			SDL_SendKeyboardKey( 0, SDL_PRESSED, code);
			SDL_SendKeyboardKey( 0, SDL_RELEASED, code);
			if (mod & KMOD_SHIFT) {
				/* If character uses shift, press shift back up */
				SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_LSHIFT);
			}
		}
	}
	return NO; /* don't allow the edit! (keep placeholder text there) */
}

/* Terminates the editing session */
- (BOOL)textFieldShouldReturn:(UITextField*)_textField {
	//[self hideKeyboard];
    SDL_SendKeyboardKey( 0, SDL_PRESSED, SDL_SCANCODE_RETURN);
    SDL_SendKeyboardKey( 0, SDL_RELEASED, SDL_SCANCODE_RETURN);
	return NO;
}

#endif

@end

/* iPhone keyboard addition functions */
#if SDL_IPHONE_KEYBOARD

int SDL_iPhoneKeyboardShow(SDL_Window * window) {
	
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (nil == view) {
		SDL_SetError("Window has no view");
		return -1;
	}
	else {
		[view showKeyboard];
		return 0;
	}
}

int SDL_iPhoneKeyboardHide(SDL_Window * window) {
	
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (NULL == view) {
		SDL_SetError("Window has no view");
		return -1;
	}
	else {
		[view hideKeyboard];
		return 0;
	}
}

SDL_bool SDL_iPhoneKeyboardIsShown(SDL_Window * window) {
	
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (NULL == view) {
		SDL_SetError("Window has no view");
		return 0;
	}
	else {
		return view.keyboardVisible;
	}
}

int SDL_iPhoneKeyboardToggle(SDL_Window * window) {
	
	SDL_WindowData *data;
	SDL_uikitview *view;
	
	if (NULL == window) {
		SDL_SetError("Window does not exist");
		return -1;
	}
	
	data = (SDL_WindowData *)window->driverdata;
	view = data->view;
	
	if (NULL == view) {
		SDL_SetError("Window has no view");
		return -1;
	}
	else {
		if (SDL_iPhoneKeyboardIsShown(window)) {
			SDL_iPhoneKeyboardHide(window);
		}
		else {
			SDL_iPhoneKeyboardShow(window);
		}
		return 0;
	}
}

#else

/* stubs, used if compiled without keyboard support */

int SDL_iPhoneKeyboardShow(SDL_Window * window) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

int SDL_iPhoneKeyboardHide(SDL_Window * window) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}

SDL_bool SDL_iPhoneKeyboardIsShown(SDL_Window * window) {
	return 0;
}

int SDL_iPhoneKeyboardToggle(SDL_Window * window) {
	SDL_SetError("Not compiled with keyboard support");
	return -1;
}


#endif /* SDL_IPHONE_KEYBOARD */
