//
//  SpeechRecoginzerCore.m
//  SpeakRecognizerTakePhoto
//
//  Created by Sylar on 16/12/9.
//  Copyright © 2016年 Sylar. All rights reserved.
//

#import "SpeechRecoginzerCore.h"
#import <Speech/Speech.h>

//用于画波
#include <Accelerate/Accelerate.h>  //Include the Accelerate framework to perform FFT


//----> 网上画波的傅里叶参数...
const Float64 sampleRate = 44100.0;
const UInt32 frequency = 2205;//傅里叶变换的点数（相当于每次有frequency个frame去参与傅里叶变换）



@interface SpeechRecoginzerCore ()<SFSpeechRecognizerDelegate>
{
    SFSpeechRecognizer *speechRecognizer;//这个类是语音识别的操作类，用于语音识别用户权限的申请，语言环境的设置，语音模式的设置以及向Apple服务发送语音识别的请求
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;//通过音频流来创建语音识别请求
    SFSpeechRecognitionTask *recognitionTask;//这个类是语音识别服务请求任务类，每一个语音识别请求都可以抽象为一个SFSpeechRecognitionTask实例，其中SFSpeechRecognitionTaskDelegate协议中约定了许多请求任务过程中的监听方法
    AVAudioEngine *audioEngine;
}

@property (nonatomic, assign) NSInteger samplingFrequency;
@property (nonatomic, assign, readonly) NSInteger frequencyDataCountBelow20kHz;
@property (nonatomic, assign) NSInteger frequencyChannelCount;

@end

@implementation SpeechRecoginzerCore

-(void)dealloc
{
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
    }
    
    if (recognitionTask!=nil) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    
    if (recognitionRequest) {
        recognitionRequest = nil;
    }
    
    if (audioEngine) {
        audioEngine = nil ;
    }
}

-(instancetype)initWithLocaleIdentifier:(NSString *)localeIdentifier
{
    if (self = [super init]) {
        
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
        
        NSAssert(localeIdentifier!=nil, @"localeIdentifier is UnKnown");
        
        speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier]];
        
        NSAssert(speechRecognizer != nil, @"SpeechRecognizer Can't Init");
        
        audioEngine = [[AVAudioEngine alloc] init];
        
        speechRecognizer.delegate = self;
        
        _isRecording = NO;
        
    }
    return self;
}


-(void)startRecording
{
     _isRecording = YES;
    
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
    }

    if (recognitionTask != nil) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    @try {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
        [audioSession setActive:YES error:nil];
    } @catch (NSException *exception) {
        NSLog(@"audioSession properties weren't set because of an error.");
    } @finally {
    }

    if (recognitionRequest) {
        recognitionRequest = nil;
    }
    
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
//    recognitionRequest.shouldReportPartialResults = YES;
    NSAssert(recognitionRequest != nil, @"Unable to create an SFSpeechAudioBufferRecognitionRequest object");
    
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    
    NSAssert(inputNode != nil, @"Audio engine has no input node");
    
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        bool isFinal = NO;
        NSLog(@"-----------  %@",result);
        if (result != nil) {
            //识别中
            isFinal = result.isFinal;
            
            if ([self.delegate respondsToSelector:@selector(speechRecognizerDidRecognizeText:)]) {
                [self.delegate speechRecognizerDidRecognizeText:result.bestTranscription.formattedString];
            }
        }
        if (error != nil || isFinal) {
            
            //识别完成
            [audioEngine stop];
            [inputNode removeTapOnBus:0];
            recognitionRequest = nil ;
            recognitionTask = nil ;

            if (error!=nil) {
                if ([self.delegate respondsToSelector:@selector(speechRecogizerWithFatalerror:)]) {
                    [self.delegate speechRecogizerWithFatalerror:error];
                }
            }
            else if (isFinal)
            {
                if ([self.delegate respondsToSelector:@selector(speechRecognizerDidFinishRecognize)]) {
                    [self.delegate speechRecognizerDidFinishRecognize];
                }
            }
        }
    }];
    
    AVAudioFormat *format = [inputNode outputFormatForBus:0];

    _samplingFrequency = sampleRate;
    
    _frequencyDataCountBelow20kHz = (NSInteger)(frequency * (20000.0 / _samplingFrequency));
    if (_frequencyChannelCount <= 0) {
        _frequencyChannelCount = _frequencyDataCountBelow20kHz;
    }

    _FrequencyData = (Float32 *)calloc(frequency, sizeof(Float32));

    [inputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        
        [recognitionRequest appendAudioPCMBuffer:buffer];

//        performFFT(&buffer.floatChannelData[0][0], frequency * 2, _FrequencyData);
        
    }];
    
    [audioEngine prepare];
    
    @try {
        [audioEngine startAndReturnError:nil];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}


-(void)stopRecording
{
    _isRecording = NO;
    
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
    }
    
    if (recognitionTask!=nil) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
}



//FFT
static void performFFT(float* data, UInt32 numberOfFrames, Float32 *frequencyData) {
    
    int bufferLog2 = round(log2(numberOfFrames));
    float fftNormFactor = 1.0/( 2 * numberOfFrames);
    
    FFTSetup fftSetup = vDSP_create_fftsetup(bufferLog2, kFFTRadix2);
    
    int numberOfFramesOver2 = numberOfFrames / 2;
    float outReal[numberOfFramesOver2];
    float outImaginary[numberOfFramesOver2];
    
    COMPLEX_SPLIT output = { .realp = outReal, .imagp = outImaginary };
    
    //Put all of the even numbered elements into outReal and odd numbered into outImaginary
    vDSP_ctoz((COMPLEX *)data, 2, &output, 1, numberOfFramesOver2);
    
    //Perform the FFT via Accelerate
    //Use FFT forward for standard PCM audio
    vDSP_fft_zrip(fftSetup, &output, 1, bufferLog2, FFT_FORWARD);
    
    //Scale the FFT data
    vDSP_vsmul(output.realp, 1, &fftNormFactor, output.realp, 1, numberOfFramesOver2);
    vDSP_vsmul(output.imagp, 1, &fftNormFactor, output.imagp, 1, numberOfFramesOver2);
    
    //vDSP_zvmags(&output, 1, soundBuffer[inBusNumber].frequencyData, 1, numberOfFramesOver2);
    
    //Take the absolute value of the output to get in range of 0 to 1
    //vDSP_zvabs(&output, 1, frequencyData, 1, numberOfFramesOver2);
    vDSP_zvabs(&output, 1, frequencyData, 1, numberOfFramesOver2);
    
    vDSP_destroy_fftsetup(fftSetup);
}



- (NSMutableArray<NSNumber *> *)FrequencyValue
{
    if (!_FrequencyValue) {
        _FrequencyValue = [NSMutableArray arrayWithCapacity:frequency];
    }
    //只取20kHz以下的数据
    for (int i = 0; i < _frequencyChannelCount; i ++) {
        [_FrequencyValue setObject:[NSNumber numberWithFloat:_FrequencyData[i]] atIndexedSubscript:i];
    }
    return _FrequencyValue;
}


@end
