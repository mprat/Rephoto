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
    
    PointCloudProcessing *pointCloudProcessing;
    CVPixelBufferRef pixelBuffer;
}
@end

@implementation CameraViewController

@synthesize captureSession = _captureSession;
@synthesize motionManager = _motionManager;
@synthesize previewLayer = _previewLayer;
@synthesize timestamp = _timestamp;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    accelerometer_available = false;
    device_motion_available = false;
	
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
    
    // what is this for, actually?
//    double max_fps = 30;
//    for(int i = 0; i < [[output connections] count]; i++) {
//        AVCaptureConnection *conn = [[output connections] objectAtIndex:i];
//        if (conn.supportsVideoMinFrameDuration) {
//            conn.videoMinFrameDuration = CMTimeMake(1, max_fps);
//        }
//        if (conn.supportsVideoMaxFrameDuration) {
//            conn.videoMaxFrameDuration = CMTimeMake(1, max_fps);
//        }
//    }
    
    [self.captureSession setSessionPreset: AVCaptureSessionPresetMedium];
    
    //set up the preview layer
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = self.view.frame;
    [self.view.layer addSublayer: self.previewLayer];
    
    //starts camera automatically
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(startCapture) userInfo:nil repeats:NO];

}

-(void) startCapture{
    [self.captureSession startRunning];
}

- (IBAction)SlamInitButtonPressed:(id)sender {
    //guarantee that init camera will get called before camera is started
    [self initCamera];
    
    //TODO: get x, y of click?
    pointCloudProcessing->start_match_to_image(0.0, 0.0);
}

// method to process frames, from AVCaptureVideoDataOutputSampleBufferDelegate
-(void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (sampleBuffer == nil) {
        NSLog(@"Received nil sampleBuffer from %@ with connection %@",captureOutput,connection);
        return;
    }
	
    CFRetain(sampleBuffer);
    
    NSData *data = [[NSData alloc] initWithBytesNoCopy:sampleBuffer length:4 freeWhenDone:NO];
    
	// Make sure that we handle the camera data in the main thread
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(captureOutputHelper:) withObject:data waitUntilDone:true];
    } else {
        [self captureOutputHelper: data];
    }
	
    CFRelease(sampleBuffer);
}

// do pixel processing here (on the main thread)
-(void) captureOutputHelper:(id)pixelData{
    NSData * data = (NSData *) pixelData;
    
    CMSampleBufferRef sampleBuffer = (CMSampleBufferRef) [data bytes];
    
    self.timestamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
    
    CVImageBufferRef imgBuff = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(imgBuff);
    CVPixelBufferRef pixBuff = imgBuff;
    
    int w = CVPixelBufferGetWidth(pixBuff);
    int h = CVPixelBufferGetHeight(pixBuff);
	
	
	// Create the application once we get the first camera frame
	if (!pointCloudProcessing) {
		NSString *resourcePath = [NSString stringWithFormat:@"%@/", [[NSBundle mainBundle] resourcePath]];
        
		pointCloudProcessing = new PointCloudProcessing(self.view.bounds.size.width,
											self.view.bounds.size.height,
											w,
											h,
											POINTCLOUD_BGRA_8888,
											[resourcePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
	pixelBuffer = pixBuff;
    
    //process pixel buffer---
    CVReturn lockResult = CVPixelBufferLockBaseAddress (pixelBuffer, 0);
	if(lockResult == kCVReturnSuccess) {
		if (accelerometer_available) {
			if (!self.motionManager.accelerometerActive)
				[self.motionManager startAccelerometerUpdates];
			
			CMAccelerometerData *accelerometerData = self.motionManager.accelerometerData;
			if (accelerometerData) {
				CMAcceleration acceleration = accelerometerData.acceleration;
				
				pointCloudProcessing->on_accelerometer_update(acceleration.y, acceleration.x, acceleration.z, self.timestamp);
			}
		}
		if (device_motion_available) {
			if (!self.motionManager.deviceMotionActive)
				[self.motionManager startDeviceMotionUpdates];
			
			CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
			if (deviceMotion) {
				CMAcceleration device_acceleration = deviceMotion.userAcceleration;
				CMRotationRate device_rotation_rate = deviceMotion.rotationRate;
                CMAcceleration gravity = deviceMotion.gravity;
				
				pointCloudProcessing->on_device_motion_update(device_acceleration.y,
															   device_acceleration.x,
															   device_acceleration.z,
															   device_rotation_rate.y,
															   device_rotation_rate.x,
															   device_rotation_rate.z,
                                                               gravity.y,
                                                               gravity.x,
                                                               gravity.z,
                                                               self.timestamp);
			}
		}
		
		char* ba = (char*)CVPixelBufferGetBaseAddress(pixelBuffer);
        
		pointCloudProcessing->frame_process(ba, self.timestamp);
		
		CVPixelBufferUnlockBaseAddress (pixelBuffer, 0);
	}
	
    pixelBuffer = nil;
	
    CFRelease(imgBuff);
}

@end
