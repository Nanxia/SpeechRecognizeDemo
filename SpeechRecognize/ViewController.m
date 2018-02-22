//
//  ViewController.m
//  SpeechRecognize
//
//  Created by Sylar on 16/12/13.
//  Copyright © 2016年 Sylar. All rights reserved.
//

#import "ViewController.h"
#import "PCHSpeechRecognizer.h"
#import "PCHSpeechRecoginzerCore.h"
#import "MBProgressHUD.h"

static CGFloat const PCHStartButtonW = 70.0;
static CGFloat const PCHStartButtonH = 30.0;

@interface ViewController ()

@property (nonatomic, strong) PCHSpeechRecognizer *pchSpeech;
@property (nonatomic, strong) PCHSpeechRecoginzerCore *pchSpeechCore;
@property (nonatomic, strong) UIButton *startBtn, *stopBtn;
//@property (nonatomic, strong) UILabel *textLab;
@property (nonatomic, strong) UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.textField];
    [self.view addSubview:self.startBtn];
    [self.view addSubview:self.stopBtn];
}

- (PCHSpeechRecognizer *)pchSpeech
{
    if (!_pchSpeech) {
        __weak typeof(self) weakSelf = self;
        _pchSpeech = [[PCHSpeechRecognizer alloc] init];
        _pchSpeech.srHandler = ^(NSString *text) {
            weakSelf.textField.text = text;
        };
    }
    return _pchSpeech;
}

- (PCHSpeechRecoginzerCore *)pchSpeechCore
{
    if (!_pchSpeechCore) {
        __weak typeof(self) weakSelf = self;
        _pchSpeechCore = [[PCHSpeechRecoginzerCore alloc] initWithLocaleIdentifier:@"zh_CN"];
        _pchSpeechCore.startHandler = ^(NSString *text) {
//            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        };
        _pchSpeechCore.stopHandler = ^(NSString *text) {
            weakSelf.textField.text = text;
            [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        };
    }
    return _pchSpeechCore;
}

- (UITextField *)textField
{
    if (!_textField) {
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 50, self.view.frame.size.width-20, 70)];
        _textField.text = @"弹幕";
        _textField.backgroundColor = [UIColor blueColor];
    }
    return _textField;
}

//- (UILabel *)textLab
//{
//    if (!_textLab) {
//        _textLab = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, self.view.frame.size.width-20, 70)];
//        _textLab.text = @"弹幕";
//        _textLab.numberOfLines = 0;
//        _textLab.backgroundColor = [UIColor blueColor];
//    }
//    return _textLab;
//}

- (UIButton *)startBtn
{
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setFrame:CGRectMake(50, self.view.frame.size.height-PCHStartButtonH-10, PCHStartButtonW, PCHStartButtonH)];
        [_startBtn setTitle:@"start" forState:UIControlStateNormal];
        [_startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_startBtn addTarget:self action:@selector(start:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UIButton *)stopBtn
{
    if (!_stopBtn) {
        _stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopBtn setFrame:CGRectMake(self.view.frame.size.width-120, self.view.frame.size.height-PCHStartButtonH-10, PCHStartButtonW, PCHStartButtonH)];
        [_stopBtn setTitle:@"stop" forState:UIControlStateNormal];
        [_stopBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_stopBtn addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}

- (void)start:(id)sender
{
//    [self.pchSpeech start];
    [self.pchSpeechCore startRecording];
}

- (void)stop:(id)sender
{
//    [self.pchSpeech stop];
    [self.pchSpeechCore stopRecording];
}

@end
