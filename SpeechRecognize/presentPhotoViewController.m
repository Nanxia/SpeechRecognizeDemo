//
//  presentPhotoViewController.m
//  SpeakRecognizerTakePhoto
//
//  Created by Sylar on 16/12/9.
//  Copyright © 2016年 Sylar. All rights reserved.
//

#import "presentPhotoViewController.h"

@interface presentPhotoViewController ()
{
    UIImageView *imageView;
}
@end

@implementation presentPhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    imageView = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:imageView];
    imageView.image = _presentImage;
    imageView.image = _presentImage;
    imageView.userInteractionEnabled = YES ;
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 100 , 50, 50)];
    button.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(popController) forControlEvents:UIControlEventTouchUpInside];
}

-(void)popController
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

@end
