//
//  CameraSpeechReconizeControllerViewController.m
//  SpeechRecognize
//
//  Created by Sylar on 16/12/13.
//  Copyright © 2016年 Sylar. All rights reserved.
//

#import "CameraSpeechReconizeControllerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SpeechRecoginzerCore.h"
#import "presentPhotoViewController.h"


@interface CameraSpeechReconizeControllerViewController ()<SpeechRecognizerCoreDelegate,UITableViewDelegate,UITableViewDataSource>
{
    NSArray *modelArray;
    UIButton *recordButton;
    AVCaptureDevicePosition position_;
    AVCaptureDevice *camera_;
    NSInteger currentSelectIdentifier;
}
@property (nonatomic, strong)AVCaptureSession            * session;
@property (nonatomic, strong)AVCaptureDeviceInput        * videoInput;
@property (nonatomic, strong)AVCaptureStillImageOutput   * stillImageOutput;
@property (nonatomic, strong)AVCaptureVideoPreviewLayer  * previewLayer;

@property (nonatomic, strong)UIButton             * toggleButton;
@property (nonatomic, strong)UIButton             * shutterButton;

@property (nonatomic, strong)SpeechRecoginzerCore *speechCore;
@property(nonatomic,strong)UITableView *tableview;

@end

@implementation CameraSpeechReconizeControllerViewController

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initialSession];
    
    currentSelectIdentifier = 0 ;
    
    _speechCore = [[SpeechRecoginzerCore alloc]initWithLocaleIdentifier:@"zh-hk"];
    _speechCore.delegate = self ;
    
    recordButton  = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width /2 , [UIScreen mainScreen].bounds.size.height - 100, 60, 60)];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    recordButton.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:recordButton];
    [recordButton addTarget:self action:@selector(recordButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    modelArray = @[@"zh-hk",@"en-US", @"zh-CN"];
    
    _tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, 90, 200, 60) style:UITableViewStylePlain];
    [self.view addSubview:_tableview];
    _tableview.dataSource = self;
    _tableview.delegate = self ;
    
    UIButton *switchCameraButton = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width /2  - 80 , [UIScreen mainScreen].bounds.size.height - 100, 60, 60)];
    switchCameraButton.backgroundColor = [UIColor blueColor];
    [self.view addSubview:switchCameraButton];
    [switchCameraButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [switchCameraButton setTitle:@"Switch" forState:UIControlStateNormal];
    [switchCameraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIButton *dimssButton = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width /2  + 80 , [UIScreen mainScreen].bounds.size.height - 100, 60, 60)];
    dimssButton.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:dimssButton];
    [dimssButton addTarget:self action:@selector(dismissController) forControlEvents:UIControlEventTouchUpInside];
    [dimssButton setTitle:@"Back" forState:UIControlStateNormal];
    [dimssButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

-(void)dismissController
{
    if (_speechCore.isRecording) {
        [_speechCore stopRecording];
        _speechCore.delegate = nil ;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)recordButtonTap:(UIButton*)sender
{
    if (_speechCore.isRecording) {
        [_speechCore stopRecording];
        sender.backgroundColor = [UIColor whiteColor];
    }
    else{
        sender.backgroundColor = [UIColor greenColor];
        [_speechCore startRecording];
    }
}

#pragma mark - tableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return modelArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = modelArray[indexPath.row];
    
    if (indexPath.row == currentSelectIdentifier) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark ;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"indexPath:%ld , language:%@",indexPath.row,modelArray[indexPath.row]);
    
     UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentSelectIdentifier inSection:0]];
    
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    
    currentSelectIdentifier = indexPath.row ;
    
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (_speechCore.isRecording) {
        [_speechCore stopRecording];
        _speechCore = nil;
        recordButton.backgroundColor = [UIColor whiteColor];
    }
    
    _speechCore = [[SpeechRecoginzerCore alloc]initWithLocaleIdentifier:modelArray[indexPath.row]];
    _speechCore.delegate = self;
}


-(void)initialSession
{
    self.session = [[AVCaptureSession alloc] init];
    self.previewLayer =  [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer addSublayer:self.previewLayer];
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:nil];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    position_ = AVCaptureDevicePositionFront;
}

- (AVCaptureDevice *)frontCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            camera_ = device;
            return device;
        }
    }
    return nil;
}

-(void)speechRecognizerDidFinishRecognize
{
    [_speechCore stopRecording];
    recordButton.backgroundColor = [UIColor whiteColor];
}

-(void)speechRecognizerDidRecognizeText:(NSString *)text
{
    NSLog(@"text:%@",text);
    
    if ([text containsString:@"拍照"] || [text containsString:@"影相"]) {
        
        if (position_ == AVCaptureDevicePositionFront) {
            [self takePhoto];
        }
        else
        {
            if ([camera_ hasTorch]) {
                [self blink];
            }
            else
            {
                [self takePhoto];
            }
        }
    }
}

-(void)blink
{
    [self performSelector:@selector(openTorch) withObject:nil afterDelay:0.0f];
    [self performSelector:@selector(closeTorch) withObject:nil afterDelay:0.2f];
    [self performSelector:@selector(openTorch) withObject:nil afterDelay:0.4f];
    [self performSelector:@selector(closeTorch) withObject:nil afterDelay:0.6f];
    
    [self takePhoto];
}

-(void)openTorch
{
    if ([camera_ hasTorch]) {
        [camera_ lockForConfiguration:nil];
        //        [camera_ setTorchMode:AVCaptureTorchModeOn];
        [camera_ setTorchModeOnWithLevel:0.1f error:nil];
        [camera_ unlockForConfiguration];
    }
}

-(void)closeTorch
{
    if ([camera_ hasTorch]) {
        [camera_ lockForConfiguration:nil];
        [camera_ setTorchMode:AVCaptureTorchModeOff];
        [camera_ unlockForConfiguration];
    }
}

-(void)switchCamera
{
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition newPosition;
    
    if (position_ == AVCaptureDevicePositionBack)
    {
        newPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        newPosition = AVCaptureDevicePositionBack;
    }
    camera_ = nil;
    
    position_  = newPosition;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == newPosition)
        {
            camera_ = device;
        }
    }
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera_ error:&error];
    
    if (newVideoInput != nil)
    {
        [_session beginConfiguration];
        
        [_session removeInput:self.videoInput];
        if ([_session canAddInput:newVideoInput])
        {
            [_session addInput:newVideoInput];
            
            self.videoInput = newVideoInput;
        }
        else
        {
            [_session addInput:self.videoInput];
        }
        
        [_session commitConfiguration];
    }
}


-(void)takePhoto
{
    AVCaptureConnection * videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    [_speechCore stopRecording];
    
    recordButton.backgroundColor = [UIColor whiteColor];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        UIImage * image = [UIImage imageWithData:imageData];
        
        NSLog(@"image size = %@",NSStringFromCGSize(image.size));
        
        presentPhotoViewController *present = [[presentPhotoViewController alloc]init];
        present.presentImage = image;
        
        [self presentViewController:present animated:YES completion:^{
            
        }];
    }];
}

-(void)speechRecogizerWithFatalerror:(NSError *)error
{
    [_speechCore stopRecording];
    recordButton.backgroundColor = [UIColor whiteColor];
}

@end
