//
//  OnozOmgView.h
//  AnimatedWallpaperTest
//
//  Created by Hamza Sood on 19/07/2013.
//  Copyright (c) 2013 Hamza Sood. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <SpringBoardFoundation/SpringBoardFoundation.h>

@interface OnozOmgView : SBFProceduralWallpaper <GLKViewDelegate> {
    CADisplayLink *_displayLink;
    GLKView *_glView;
    GLKBaseEffect *_baseEffect;
    NSMutableArray *_textureInfoArray;
}
@end
