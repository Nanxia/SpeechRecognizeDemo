//
//  recognizeViewController.m
//  SpeechRecognize
//
//  Created by Sylar on 16/12/13.
//  Copyright © 2016年 Sylar. All rights reserved.
//

#import "recognizeViewController.h"
#import "SpeechRecoginzerCore.h"

@interface recognizeViewController ()<SpeechRecognizerCoreDelegate>

@property (weak, nonatomic) IBOutlet UIButton *CantonButton;
@property (weak, nonatomic) IBOutlet UIButton *MainLandButton;
@property (weak, nonatomic) IBOutlet UIButton *USButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *recButton;

@property (nonatomic, strong) SpeechRecoginzerCore *speechCore;

@end

@implementation recognizeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _textView.text = @"";
    
    if (_speechCore) {
        _speechCore = nil ;
    }
    _speechCore = [[SpeechRecoginzerCore alloc] initWithLocaleIdentifier:@"zh-CN"];
    _speechCore.delegate = self ;
    _recButton.enabled = YES;
}

- (IBAction)CantonClick:(UIButton *)sender
{
//    _MainLandButton.enabled = NO;
//    _USButton.enabled = NO;
//    _CantonButton.enabled = NO;
    if (_speechCore) {
        _speechCore = nil ;
    }
    _speechCore = [[SpeechRecoginzerCore alloc] initWithLocaleIdentifier:@"zh-hk"];
    _speechCore.delegate = self ;
    _recButton.enabled = YES;
    
}

- (IBAction)MainLandClick:(id)sender
{
//    _CantonButton.enabled = NO;
//    _USButton.enabled = NO;
//    _MainLandButton.enabled = NO;
    if (_speechCore) {
        _speechCore = nil ;
    }
    _speechCore = [[SpeechRecoginzerCore alloc] initWithLocaleIdentifier:@"zh-CN"];
    _speechCore.delegate = self ;
    _recButton.enabled = YES;
    
}

- (IBAction)enUSClick:(id)sender
{
//    _MainLandButton.enabled = NO;
//    _CantonButton.enabled = NO;
//    _USButton.enabled = NO;
    if (_speechCore) {
        _speechCore = nil ;
    }
    _speechCore = [[SpeechRecoginzerCore alloc] initWithLocaleIdentifier:@"en-US"];
    _speechCore.delegate = self ;
    _recButton.enabled = YES;
    
}


- (IBAction)recButtonClick:(id)sender
{
    if (_speechCore.isRecording) {
        [_speechCore stopRecording];
        _CantonButton.enabled = YES;
        _USButton.enabled = YES;
        _MainLandButton.enabled = YES;
        [_recButton setTitle:@"Start Recording" forState:UIControlStateNormal];
    }else{
        _textView.text = @"";
        _CantonButton.enabled = NO;
        _USButton.enabled = NO;
        _MainLandButton.enabled = NO;
        [_recButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
        [_speechCore startRecording];
    }
}

-(void)speechRecogizerWithFatalerror:(NSError *)error
{
    _CantonButton.enabled = YES;
    _USButton.enabled = YES;
    _MainLandButton.enabled = YES;
    [_recButton setTitle:@"Start Recording" forState:UIControlStateNormal];
}

-(void)speechRecognizerDidFinishRecognize
{
    _CantonButton.enabled = YES;
    _USButton.enabled = YES;
    _MainLandButton.enabled = YES;
    [_recButton setTitle:@"Start Recording" forState:UIControlStateNormal];
}

-(void)speechRecognizerDidRecognizeText:(NSString *)text
{
    NSLog(@"RecognizeText            :%@",text);
    _textView.text = text;
}

- (IBAction)back:(id)sender
{
    if (_speechCore.isRecording) {
        [_speechCore stopRecording];
        _speechCore.delegate = nil;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
