//
//  CameraViewController.h
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIAlertViewDelegate> {
}

@property (strong, nonatomic) AVCaptureSession *captureSession;

-(void)startCapture;

@end
