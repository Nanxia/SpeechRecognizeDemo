//
//  PCHSpeechRecognizer.m
//  SpeechRecognize
//
//  Created by liao.zq on 14/12/17.
//  Copyright © 2017年 Sylar. All rights reserved.
//

#import "PCHSpeechRecognizer.h"
#import <Speech/Speech.h>

@interface PCHSpeechRecognizer()<SFSpeechRecognitionTaskDelegate, AVAudioRecorderDelegate>

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

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechRecognitionRequest *srRequest;

@end

@implementation PCHSpeechRecognizer

#pragma mark - init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupRecorder];
//        [self setUpTimer];
    }
    return self;
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
    
    NSString *recordPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"record1.caf"];
    _recordURL = [NSURL fileURLWithPath:recordPath];
    _recorder = [[AVAudioRecorder alloc] initWithURL:_recordURL settings:recordSettings error:NULL];
    _recorder.delegate = self;
    _recorder.meteringEnabled = YES;
    
}

- (void)setUpTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}

- (SFSpeechRecognizer *)speechRecognizer
{
    if (!_speechRecognizer) {
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    }
    return _speechRecognizer;
}

- (SFSpeechRecognitionRequest *)srRequest
{
    if (!_srRequest) {
        _srRequest = [[SFSpeechURLRecognitionRequest alloc] initWithURL:self.recordURL];
    }
    return _srRequest;
}

#pragma mark - action

- (void)start
{
    
    if (!self.recorder.isRecording) {
        NSLog(@"开始录音");
        [self.recorder record];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
    }
}

- (void)stop
{
    
    if (self.recorder.isRecording) {
     NSLog(@"停止录音");
        [self.recorder stop];
        [self.timer invalidate];
    }
    
    
    
    //创建语音识别操作类对象
    //    SFSpeechRecognizer *rec = [[SFSpeechRecognizer alloc]initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
    //
    ////    通过一个本地的音频文件来解析
    //    SFSpeechURLRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1122334455.mp3" ofType:nil]]];
    //    [rec recognitionTaskWithRequest:request delegate:self];
}

- (void)updateTimer
{
    static BOOL isStartRecorder = NO;
    // 不更新就没法用了
    [self.recorder updateMeters];
    
    // 获得0声道的音量，完全没有声音-160.0，0是最大音量
    float power = [self.recorder peakPowerForChannel:0];
    
    if (power > -20) { //抓取到声音
        NSLog(@"luyingkai     shi");
        isStartRecorder = YES;
//        [self.recorder deleteRecording];
//        [self.recorder record];
//        [self.timer invalidate];
    } else if (isStartRecorder) {
        NSLog(@"luyingjie     su");
        isStartRecorder = NO;
        [self stop];
    }
}

#pragma mark - SFSpeechRecognitionTaskDelegate

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult
{
    NSLog(@"识别成功：  %@",recognitionResult.bestTranscription.formattedString);
    
    if (self.srHandler) {
        self.srHandler(recognitionResult.bestTranscription.formattedString);
    }
    
//    [self.recorder deleteRecording];
    [self start];
}

- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task
{
    NSLog(@"speechRecognitionDidDetectSpeech");
}

//// Called for all recognitions, including non-final hypothesis
//- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription
//{
//    NSLog(@"didHypothesizeTranscription");
//}
//
//// Called when the task is no longer accepting new audio but may be finishing final processing
//- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task
//{
//    NSLog(@"speechRecognitionTaskFinishedReadingAudio");
//}
//
//// Called when the task has been cancelled, either by client app, the user, or the system
//- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task
//{
//    NSLog(@"speechRecognitionTaskWasCancelled");
//}
//
//// Called when recognition of all requested utterances is finished.
//// If successfully is false, the error property of the task will contain error information
//- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully
//{
//    NSLog(@"didFinishSuccessfully");
//}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"RecorderDidFinish");
    [self.speechRecognizer recognitionTaskWithRequest:self.srRequest delegate:self];
}

//- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
//{
//    NSLog(@"RecorderEncodeError");
//}
//
//- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder NS_DEPRECATED_IOS(2_2, 8_0)
//{
//    NSLog(@"RecorderBeginInterruption");
//}
//
//- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags NS_DEPRECATED_IOS(6_0, 8_0)
//{
//    NSLog(@"RecorderEndInterruption  withOptions");
//}
//
//- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags NS_DEPRECATED_IOS(4_0, 6_0)
//{
//    NSLog(@"RecorderEndInterruption  withFlags");
//}
//
//- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder NS_DEPRECATED_IOS(2_2, 6_0)
//{
//    NSLog(@"RecorderEndInterruption");
//}


@end
