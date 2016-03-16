//
//  DemoVC.m
//  QHPay
//
//  Created by liqunfei on 16/3/16.
//  Copyright © 2016年 chenlizhu. All rights reserved.
//

#import "DemoVC.h"
#import "CCPClipCaremaImage.h"
#define MAINSCREEN_BOUNDS  [UIScreen mainScreen].bounds


@interface DemoVC()
{
    CCPClipCaremaImage *view;
    UIImageView *imgV;
}

@end

@implementation DemoVC
- (void)buildUI {
    if (!view) {
       
        view = [[CCPClipCaremaImage alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:view];
        [self.view sendSubviewToBack:view];
    }
    [view startCamera];
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [flashButton setBackgroundImage:[UIImage imageNamed:@"iconfont-llalbumflashon.png"] forState:UIControlStateNormal];
    flashButton.frame = CGRectMake(MAINSCREEN_BOUNDS.size.width - 50, 20, 30, 30);
    [flashButton addTarget:self action:@selector(flashAction:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *takePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];

    [takePhotoButton setTitle:@"拍照" forState:UIControlStateNormal];
    takePhotoButton.titleLabel.textColor = [UIColor colorWithRed:82 green:172 blue:205 alpha:1.0];
    takePhotoButton.frame = CGRectMake(self.view.center.x - 40, MAINSCREEN_BOUNDS.size.height - 50, 80, 20);
    [takePhotoButton addTarget:self action:@selector(takePhotoAction:) forControlEvents:UIControlEventTouchUpInside];
    imgV = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imgV.contentMode = UIViewContentModeScaleAspectFit;
    imgV.image = nil;
    imgV.hidden = YES;
    [self.view insertSubview:imgV aboveSubview:view];
    [self.view addSubview:flashButton];
    [self.view addSubview:takePhotoButton];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    imgV.image = nil;
    imgV.hidden = YES;
}

- (void)viewDidLoad {
    [self buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [view stopCamera];
}


- (void)flashAction:(UIButton *)sender {
    if ([view isOpenFlash]) {
        [sender setImage:[UIImage imageNamed:@"iconfont-llalbumflashon (1)"] forState:UIControlStateNormal];
    }
    else {
        [sender setImage:[UIImage imageNamed:@"iconfont-llalbumflashon"] forState:UIControlStateNormal];
    }
}

- (void)takePhotoAction:(UIButton *)sender {
    [view takePhotoWithCommit:^(UIImage *image) {
        imgV.image = image;
        imgV.hidden = NO;
    }];
}

@end

