//
//  CameraViewController.m
//  Rephoto
//
//  Created by Michele Pratusevich on 2/26/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import "CameraViewController.h"
#import "PointView.h"
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//attribute enums
enum {
    ATTRIB_POINTPOS
};

//uniform enums
enum {
    UNIFORM_MODELVIEWPROJECTION,
    UNIFORM_POINTCOLOR,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];

@interface CameraViewController (){
    BOOL accelerometer_available;
    BOOL device_motion_available;
    
    PointCloudProcessing *pointCloudProcessing;
    CVPixelBufferRef pixelBuffer;
//    GraphicsSingleton *graphicsSing;
    
    GLuint _program;
    GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;

@end

@implementation CameraViewController

@synthesize captureSession = _captureSession;
@synthesize motionManager = _motionManager;
@synthesize previewLayer = _previewLayer;
@synthesize pointLayer = _pointLayer;
@synthesize timestamp = _timestamp;
@synthesize context = _context;
//@synthesize pointView = _pointView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    PointView* pointView = [[PointView alloc] initWithFrame:screenBounds withContext:self.context];
    //TODO: fix this alpha hack
    pointView.alpha = 0.5; //0.5 is a good value to make sure it's working (1.0 is completely opaque)
    [self.view insertSubview:pointView atIndex:0];
    
    accelerometer_available = false;
    device_motion_available = false;

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
    
//    
    [self setupGL];
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
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
    
    // if block for easy debugging
    if (true){
        //set up the preview layer
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        self.previewLayer.frame = self.view.bounds;
        //put preview layer on the bottom
        [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    }
    
    //starts camera automatically
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(startCapture) userInfo:nil repeats:NO];

}

-(void) startCapture{
    [self.captureSession startRunning];
}

- (IBAction)SlamInitButtonPressed:(id)sender {
    //guarantee that init camera will get called before camera is started
//    [self initCamera];
    
//    pointCloudProcessing->start_match_to_image();
    pointCloudProcessing->start_slam();
}

- (IBAction)SameSlamButtonPressed:(id)sender {
    NSString *documentsDirectory =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Filename" message:@"Enter filename to save as:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *filenameText = [alertView textFieldAtIndex:0];
    [alertView show];
//    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:@"test_slam_map_1"];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithString:filenameText.text]];
    pointCloudProcessing->save_slam_map([fullPath cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (IBAction)LoadSlamFromFilename:(id)sender {
    NSString *documentsDirectory =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:@"test2"];
    pointCloudProcessing->load_slam_filename([fullPath cStringUsingEncoding:NSUTF8StringEncoding]);
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
                                            machineName(),
											[resourcePath cStringUsingEncoding:[NSString defaultCStringEncoding]], _program);
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
        pointCloudProcessing->render_point_cloud();
        //any changes that are made in the frame_process code must be told to render after the frame is processed
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
		
		CVPixelBufferUnlockBaseAddress (pixelBuffer, 0);
	}
	
    pixelBuffer = nil;
	
    CFRelease(imgBuff);
}

#import <sys/utsname.h>

struct utsname systemInfo;

const char*
machineName()
{
    uname(&systemInfo);
	
    return systemInfo.machine;
}


//GRAPHICS LOADING HELPER METHODS
//TODO: move these into a graphics singleton
-(void) setupGL{    
    [self loadShaders];
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    //initialize the size of the buffer
    glBufferData(GL_ARRAY_BUFFER, 3*sizeof(float)*5012, NULL, GL_DYNAMIC_DRAW);
    
    
    //enable attribute locations
    glEnableVertexAttribArray(ATTRIB_POINTPOS);
    glVertexAttribPointer(ATTRIB_POINTPOS, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), 0);
    //    glBindVertexArrayOES(0);
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_POINTPOS, "position");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
//    uniforms[UNIFORM_MODELVIEWPROJECTION] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
//    uniforms[UNIFORM_POINTCOLOR] = glGetUniformLocation(_program, "pointcolor");
    //    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    //    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texture");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    glUseProgram(_program);
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
