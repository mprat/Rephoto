//
//  CameraViewController.m
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController (){
    BOOL accelerometer_available;
    BOOL device_motion_available;
}
@end

@implementation CameraViewController

@synthesize captureSession = _captureSession;
@synthesize motionManager = _motionManager;
@synthesize previewLayer = _previewLayer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //guarantee that init camera will get called before camera is started
	[self initCamera];
	
    //initialize the getting of accelerometer data
	self.motionManager = [[CMMotionManager alloc] init];
	
    //is there an accelerometer?
	if (self.motionManager.accelerometerAvailable) {
		accelerometer_available = true;
		[self.motionManager startAccelerometerUpdates];
	}
	
    //can i get device motion?
	if (self.motionManager.deviceMotionAvailable) {
		device_motion_available = true;
		[self.motionManager startDeviceMotionUpdates];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initCamera{    
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
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
//    dispatch_release(queue);
    
    self.captureSession = [[AVCaptureSession alloc] init];
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
    
    //set up the preview layer
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.view.layer addSublayer: self.previewLayer];
    
    //starts camera automatically
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(startCapture) userInfo:nil repeats:NO];

}

-(void) startCapture{
    [self.captureSession startRunning];
}

@end
