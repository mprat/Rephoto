//
//  CameraViewController.h
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

#import "PointCloudProcessing.h"
#import "PointView.h"
//#import "GraphicsSingleton.h"

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIAlertViewDelegate> {
//    PointView* pointView;
}

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) CALayer *pointLayer;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (weak, nonatomic) IBOutlet UILabel *PictureLabel;
@property (nonatomic) Float64 timestamp;
//@property (strong, nonatomic) PointView *pointView;

-(void)startCapture;
- (IBAction)SlamInitButtonPressed:(id)sender;
- (IBAction)SameSlamButtonPressed:(id)sender;
- (IBAction)LoadSlamFromFilename:(id)sender;
- (IBAction)BrowseRephotos:(id)sender;

@end
