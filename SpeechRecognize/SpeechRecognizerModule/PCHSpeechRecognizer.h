//
//  PCHSpeechRecognizer.h
//  SpeechRecognize
//
//  Created by liao.zq on 14/12/17.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PCHSpeechRecognizerHandler)(NSString *text);

@interface PCHSpeechRecognizer : NSObject

@property (nonatomic, copy) PCHSpeechRecognizerHandler srHandler;

- (void)start;
- (void)stop;

@end
