//
//  GraphicsSingleton.h
//  Rephoto
//
//  Created by Michele Pratusevich on 3/1/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GraphicsSingleton : NSObject

@property (nonatomic) GLuint program;


+(id) sharedInstance;
-(void) setupGLwithContext:(EAGLContext *)context;

@end
