//
//  CameraAppDelegate.h
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PointView.h"
#import "CameraViewController.h"

@interface CameraAppDelegate : UIResponder <UIApplicationDelegate>{
    PointView* pointView;
    CameraViewController *mainVC;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet PointView *pointView;
@property (strong, nonatomic) CameraViewController *mainVC;

@end
