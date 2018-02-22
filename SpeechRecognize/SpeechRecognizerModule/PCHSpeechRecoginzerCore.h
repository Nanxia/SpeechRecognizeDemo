//
//  PCHSpeechRecoginzerCore.h
//  SpeechRecognize
//
//  Created by liao.zq on 14/12/17.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PCHRecorderState)
{
    PCHRecorderStateCancel = 0,
    PCHRecorderStateStart,
    PCHRecorderStateRecording,
    PCHRecorderStateStop,
};

@protocol PCHSpeechRecognizerCoreDelegate <NSObject>

@optional

-(void)speechRecognizerDidRecognizeText:(NSString*)text;

-(void)speechRecognizerDidFinishRecognize;

-(void)speechRecogizerWithFatalerror:(NSError*)error;

@end

typedef void (^PCHSpeechRecoginzerCoreHandler)(NSString *text);


@interface PCHSpeechRecoginzerCore : NSObject

//获得权限，是否能使用框架
@property (nonatomic, readonly, assign) BOOL isUseable;
@property (nonatomic, assign) id<PCHSpeechRecognizerCoreDelegate> delegate;
@property (nonatomic, copy) PCHSpeechRecoginzerCoreHandler startHandler, stopHandler;
//获得当前是否正在识别状态
@property (nonatomic, assign, readonly) BOOL isRecording;
//获得当前录音状态
@property (nonatomic, assign) PCHRecorderState recorderState;

//传入地区编码初始化
-(instancetype)initWithLocaleIdentifier:(NSString*)localeIdentifier;


//开始识别
-(void)startRecording;


//停止识别
-(void)stopRecording;


@end
