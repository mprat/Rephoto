//
//  CameraViewController.m
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

@synthesize captureSession = _captureSession;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initCamera{
    _captureSession = [[AVCaptureSession alloc] init];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *device = nil;
    NSError *outError = nil;
    
    for(int i=0; i<[devices count] && device == nil; i++) {
        AVCaptureDevice *d = [devices objectAtIndex:i];
		if (d.position == AVCaptureDevicePositionBack && [d hasMediaType: AVMediaTypeVideo]) {
			device = d;
		}
    }
	
	if (device == nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No camera found"
														message:@"You need a device with a back-facing camera to run this app."
													   delegate:self
											  cancelButtonTitle:@"Quit"
											  otherButtonTitles:nil];
		[alert show];
		return;
	}
    
    AVCaptureDeviceInput *devInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&outError];
    
    if (!devInput) {
        NSLog(@"ERROR: %@",outError);
        return;
    }
    
	if (device == nil) {
		NSLog(@"Device is nil");
	}
	
	AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.alwaysDiscardsLateVideoFrames = YES;
    
    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
    
    [videoSettings setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*) kCVPixelBufferPixelFormatTypeKey];
    
	[output setVideoSettings:videoSettings];
    
    //TODO: figure out about camera in a different thread?
//    [output setSampleBufferDelegate:self queue:dispatch_get_current_queue()];
    
    [self.captureSession addInput:devInput];
    [self.captureSession addOutput:output];
    
    double max_fps = 30;
    
    for(int i = 0; i < [[output connections] count]; i++) {
        AVCaptureConnection *conn = [[output connections] objectAtIndex:i];
        if (conn.supportsVideoMinFrameDuration) {
            conn.videoMinFrameDuration = CMTimeMake(1, max_fps);
        }
        if (conn.supportsVideoMaxFrameDuration) {
            conn.videoMaxFrameDuration = CMTimeMake(1, max_fps);
        }
    }
    
    [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    
    NSArray *events = [NSArray arrayWithObjects:
                       AVCaptureSessionRuntimeErrorNotification,
                       AVCaptureSessionErrorKey,
                       AVCaptureSessionDidStartRunningNotification,
                       AVCaptureSessionDidStopRunningNotification,
                       AVCaptureSessionWasInterruptedNotification,
                       AVCaptureSessionInterruptionEndedNotification,
                       nil];
    
    for (id e in events) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(eventHandler:)
         name:e
         object:nil];
    }
    
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(startCamera) userInfo:nil repeats:NO];

}

-(void) startCapture{
    [self.captureSession startRunning];
}

@end
