//
//  PCHSpeechRecoginzerCore.m
//  SpeechRecognize
//
//  Created by liao.zq on 14/12/17.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "PCHSpeechRecoginzerCore.h"
#import <Speech/Speech.h>
#include <Accelerate/Accelerate.h>  //Include the Accelerate framework to perform FFT //用于画波

@interface PCHSpeechRecoginzerCore() <SFSpeechRecognitionTaskDelegate, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate>

/** 录音设备 */
@property (nonatomic, strong) AVAudioRecorder *recorder;
/** 监听设备 */
@property (nonatomic, strong) AVAudioRecorder *monitor;
/** 录音文件的URL */
@property (nonatomic, strong) NSURL *recordURL;
/** 监听器 URL */
@property (nonatomic, strong) NSURL *monitorURL;
/** 定时器 */
@property (nonatomic, strong) NSTimer *timer;
/** 音频引擎 */
@property (nonatomic, assign) NSTimeInterval startTime, stopTime;

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechRecognitionRequest *srRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;

@property (nonatomic, assign) BOOL isCancelRecording;

@end

@implementation PCHSpeechRecoginzerCore

#pragma mark - init

- (instancetype)initWithLocaleIdentifier:(NSString *)localeIdentifier
{
    if (self = [super init]) {
        [self initStatus];
        [self setupRecorder];
    }
    return self;
}

- (void)initStatus
{
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                _isUseable = YES;
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                _isUseable = NO;
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                _isUseable = NO;
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                _isUseable = NO;
                break;
            default:
                break;
        }
    }];
}

/** 设置录音环境 */
- (void)setupRecorder
{
    // 1. 音频会话
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    
    // 参数设置
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: 14400.0], AVSampleRateKey,
                                    [NSNumber numberWithInt: kAudioFormatAppleIMA4], AVFormatIDKey,
                                    [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                                    nil];
    
    NSString *recordPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"record2.caf"];
    _recordURL = [NSURL fileURLWithPath:recordPath];
    _recorder = [[AVAudioRecorder alloc] initWithURL:_recordURL settings:recordSettings error:NULL];
    _recorder.delegate = self;
    _recorder.meteringEnabled = YES;
}

- (SFSpeechRecognizer *)speechRecognizer
{
    if (!_speechRecognizer) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

- (SFSpeechRecognitionRequest *)srRequest
{
    if (!_srRequest) {
        _srRequest = [[SFSpeechURLRecognitionRequest alloc] initWithURL:self.recordURL];
        _srRequest.shouldReportPartialResults = NO;
    }
    return _srRequest;
}

#pragma mark - action

- (void)invalidateTimer
{
     [self.timer invalidate];
     self.timer = nil;
}

- (void)startRecording
{
    if (!self.recorder.isRecording) {
        NSLog(@"开始录音");
        self.recorderState = PCHRecorderStateStart;
        [self.recorder record];
        self.startTime = [[NSDate date] timeIntervalSince1970];
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
        }
    }
}

- (void)stopRecording
{
    if (self.recorder.isRecording) {
        NSLog(@"停止录音");
        [self.recorder stop];
        [self invalidateTimer];
    }
}

- (void)cancelRecording
{
    [self stopRecording];
    self.recorderState = PCHRecorderStateCancel;
}

- (void)updateTimer
{
    // 不更新就没法用了
    [self.recorder updateMeters];

    // 获得0声道的音量，完全没有声音-160.0，0是最大音量
    float power = [self.recorder peakPowerForChannel:0];
    self.recorderState = [self getRecorderStateWithPower:power];
    switch (self.recorderState) {
        case PCHRecorderStateRecording:
            NSLog(@"检测到声音,录音中...");
            break;
        case PCHRecorderStateStop:
            NSLog(@"声音结束。。。");
            [self stopRecording];
            break;
        case PCHRecorderStateCancel:
            NSLog(@"录音取消。。。");
            [self cancelRecording];
            break;
            
        default:
            break;
    }
}

- (PCHRecorderState)getRecorderStateWithPower:(float)power
{
    static BOOL isStartRecorder = NO;
    PCHRecorderState tmpState = self.recorderState;
    if (power > -20) { //截取到声音
        isStartRecorder = YES;
        tmpState = PCHRecorderStateRecording;
    } else if (isStartRecorder) {
        isStartRecorder = NO;
        tmpState = PCHRecorderStateStop;
    } else {
        self.stopTime = [[NSDate date] timeIntervalSince1970];
        if ((NSInteger)(self.stopTime - self.startTime) == 10) {
            tmpState = PCHRecorderStateCancel;
        }
    }
    return tmpState;
}

- (void)audioRecorderRecognizer
{
    NSLog(@"audioRecorderRecognizer");
    
    if (self.recognitionTask != nil) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    if (self.startHandler) {
        self.startHandler(nil);
    }
    //    __block NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    __weak typeof(self) weakSelf = self;
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.srRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        bool isFinal = NO;
        NSLog(@"-----------  %@",result.bestTranscription.formattedString);
        if (result != nil) {
            //识别中
            isFinal = result.isFinal;
            
            if (weakSelf.stopHandler) {
                weakSelf.stopHandler(result.bestTranscription.formattedString);
            }
        }
        else {
            if (weakSelf.stopHandler) {
                //                NSTimeInterval stopTime = [[NSDate date] timeIntervalSince1970];
                //                NSLog(@"%lf",(stopTime-startTime));
                weakSelf.stopHandler(@"识别错误");
            }
        }
        [weakSelf startRecording];
        
        //        if (error != nil || isFinal) {
        //
        //            if (error!=nil) {
        //                if ([weakSelf.delegate respondsToSelector:@selector(speechRecogizerWithFatalerror:)]) {
        //                    [weakSelf.delegate speechRecogizerWithFatalerror:error];
        //                }
        //            }
        //            else if (isFinal)
        //            {
        //                if ([weakSelf.delegate respondsToSelector:@selector(speechRecognizerDidFinishRecognize)]) {
        //                    [weakSelf.delegate speechRecognizerDidFinishRecognize];
        //                }
        //            }
        //        }
    }];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"RecorderDidFinish");
    if (!(self.recorderState == PCHRecorderStateCancel)) {
        [self audioRecorderRecognizer];
    }
}

@end
