//
//  CameraViewController.h
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

#import "PointCloudProcessing.h"

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
}

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (nonatomic) Float64 timestamp;

-(void)startCapture;
- (IBAction)SlamInitButtonPressed:(id)sender;

@end
