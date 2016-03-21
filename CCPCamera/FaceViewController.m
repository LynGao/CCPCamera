//
//  FaceViewController.m
//  CCPCamera
//
//  Created by liqunfei on 16/3/21.
//  Copyright © 2016年 chuchengpeng. All rights reserved.
//

#import "FaceViewController.h"
#import "CCPClipCaremaImage.h"

@interface FaceViewController()
{
    CCPClipCaremaImage *view;
    UIImageView *imgV;
}

@end

@implementation FaceViewController

- (void)buildUI {
    UIBarItem *item1 = self.tabBarController.tabBar.items[0];
    UIImage *image1 = [UIImage imageNamed:@"camera.png"];
    image1 = [image1 imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item1 setImage:image1];
    UIBarItem *item2 = self.tabBarController.tabBar.items[1];
    UIImage *image2 = [UIImage imageNamed:@"face.png"];
    image2 = [image2 imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item2 setImage:image2];
    if (!view) {
        view = [[CCPClipCaremaImage alloc] initWithFrame:self.view.bounds andFunction:@"face"];
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

- (void)viewDidLoad {
    [self buildUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [view startCamera];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [view startCamera];
}

- (void)flashAction:(UIButton *)sender {
    
}

- (void)takePhotoAction:(UIButton *)sender {
    
}

@end
