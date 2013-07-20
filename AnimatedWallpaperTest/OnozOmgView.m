//
//  OnozOmgView.m
//  AnimatedWallpaperTest
//
//  Created by Hamza Sood on 19/07/2013.
//  Copyright (c) 2013 Hamza Sood. All rights reserved.
//

#import "OnozOmgView.h"

#define kRectSize     320.0f

#define kImageOriginY 25.0f
#define kImageWidth   320.0f
#define kImageHeight  215.0f

#define kNumberOfFrames 24


@implementation OnozOmgView

#pragma mark -
#pragma mark Class Method Overrides

+ (NSString *)identifier {
    return @"ONOZOMG!!!";
}

+ (NSString *)thumbnailImageName {
    return @"thumbnail";
}

+ (BOOL)colorChangesSignificantly {
    return YES;
}




#pragma mark -
#pragma mark Procedural Wallpaper View Methods


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setBackgroundColor:[UIColor blackColor]];
        [self.layer setOpaque:YES];
        
        EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _glView = [[GLKView alloc]initWithFrame:frame context:context];
        [_glView setDelegate:self];
        [_glView setDrawableColorFormat:GLKViewDrawableColorFormatRGB565];
        [_glView setEnableSetNeedsDisplay:NO];
        [self addSubview:_glView];
        
         _displayLink = [CADisplayLink displayLinkWithTarget:_glView selector:@selector(display)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink setPaused:YES];
        
        [self _initialiseGL];
        [_glView display];
    }
    return self;
}


- (void)setAnimating:(BOOL)animating {
    [_displayLink setPaused:!animating];
}




#pragma mark -
#pragma mark OpenGL Stuff


static GLuint vertexBuffer;
static GLuint indexBuffer;


- (void)_initialiseGL {
    
    [EAGLContext setCurrentContext:_glView.context];
    
    CGPoint viewCenter = self.center;
    
    //structure: vertex coordinate followed by texture coordinate (verts on whitespace rect have 0.0f, 0.0f as texture coords)
    const GLfloat vertexData[] = {
        //Left side verticies
        viewCenter.x-0.5f*kRectSize, viewCenter.y-0.5f*kRectSize,                               0.0f, 0.0f,
        viewCenter.x-0.5f*kRectSize, viewCenter.y-0.5f*kRectSize+kImageOriginY,                 0.0f, 0.0f,
        viewCenter.x-0.5f*kRectSize, viewCenter.y-0.5f*kRectSize+kImageOriginY+kImageHeight,    0.0f, 1.0f,
        viewCenter.x-0.5f*kRectSize, viewCenter.y+0.5f*kRectSize,                               0.0f, 0.0f,
        
        //Right side verticies
        viewCenter.x+0.5f*kRectSize, viewCenter.y-0.5f*kRectSize,                               0.0f, 0.0f,
        viewCenter.x+0.5f*kRectSize, viewCenter.y-0.5f*kRectSize+kImageOriginY,                 1.0f, 0.0f,
        viewCenter.x+0.5f*kRectSize, viewCenter.y-0.5f*kRectSize+kImageOriginY+kImageHeight,    1.0f, 1.0f,
        viewCenter.x+0.5f*kRectSize, viewCenter.y+0.5f*kRectSize,                               0.0f, 0.0f
    };
    
    const GLubyte indexData[] = {
        0, 1, 4,    4, 1, 5, //Top whitespace rect
        1, 2, 5,    5, 2, 6, //Image rect
        2, 3, 6,    6, 3, 7 //Bottom whitespace rect
    };
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (2+2)*8*sizeof(GLfloat), vertexData, GL_STATIC_DRAW);
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 3*6*sizeof(GLubyte), indexData, GL_STATIC_DRAW);
    
    _baseEffect = [[GLKBaseEffect alloc]init];
    _baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(0.0f, self.bounds.size.width, self.bounds.size.height, 0, 1, -1);
    [_baseEffect setUseConstantColor:GL_TRUE];
    [_baseEffect setConstantColor:GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f)];
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), (const GLvoid *)(2*sizeof(GLfloat)));
    
    _textureInfoArray = [[NSMutableArray alloc]initWithCapacity:kNumberOfFrames];
    NSBundle *ourBundle = [NSBundle bundleForClass:self.class]; //Since we're loaded into SpringBoard, mainBundle returns SpringBoard.app
    for (int i = 1; i <= kNumberOfFrames; i++) {
        NSError *error = nil;
        GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:[ourBundle pathForResource:[NSString stringWithFormat:@"animation_%i", i] ofType:@"png" inDirectory:@"Animation"] options:nil error:&error];
        assert(error == nil); //Error handling is overrated
        [_textureInfoArray addObject:textureInfo];
    }
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    static float frameNo = 0; //Truncate for actual frame number
    
    float newGreen = 0.5*(cos(7.5*_displayLink.timestamp)+1); //Restrict range of cos to [0,1] and compress horizontally by a factor of 7.5 for faster pulsing
    glClearColor(1.0f, newGreen, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //Draw top whitespace
    _baseEffect.texture2d0.enabled = GL_FALSE;
    [_baseEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    
    //Draw image
    _baseEffect.texture2d0.enabled = GL_TRUE;
    _baseEffect.texture2d0.name = [(GLKTextureInfo *)_textureInfoArray[(int)frameNo] name];
    [_baseEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, (const GLvoid *)(6*sizeof(GLubyte)));

    //Draw bottom whitespace
    _baseEffect.texture2d0.enabled = GL_FALSE;
    [_baseEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, (const GLvoid *)(12*sizeof(GLubyte)));
    
    frameNo += 0.4f;
    if (frameNo >= kNumberOfFrames)
        frameNo = 0;
}


- (void)_destroyGL {
    [EAGLContext setCurrentContext:_glView.context];
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &indexBuffer);
}




#pragma mark -
#pragma mark Cleanup


- (void)dealloc {
    [self _destroyGL];
}


@end
