//
//  PointView.h
//  Rephoto
//
//  Created by Michele Pratusevich on 4/2/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface PointView : UIView {
    CAEAGLLayer* _eaglLayer;
//    EAGLContext* _context;
    GLuint _colorRenderBuffer;
}

- (id)initWithFrame:(CGRect)frame withContext:(EAGLContext*)context;

@end