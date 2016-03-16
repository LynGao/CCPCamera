//
//  CCPClipCaremaImage.m
//  QHPay
//
//  Created by liqunfei on 16/3/15.
//  Copyright © 2016年 chenlizhu. All rights reserved.
//

#import "CCPClipCaremaImage.h"
#import <AVFoundation/AVFoundation.h>
#define MAINSCREEN_BOUNDS  [UIScreen mainScreen].bounds
#define ScreenScaleRatio [UIScreen mainScreen].bounds.size.width/414.0
@interface CCPClipCaremaImage()
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic,strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *VPlayer;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@end

@implementation CCPClipCaremaImage

- (id) initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setUpCameraPreviewLayer];
        [self addSubview:[self makeScanCameraShadowViewWithRect]];
    }
    return self;
}

- (void)setUpCameraPreviewLayer {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        return;
    }
    if (!_VPlayer) {
        [self initSession];
        self.VPlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        self.VPlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.VPlayer.position = self.center;
        self.VPlayer.bounds = self.bounds;
        [self.layer insertSublayer:self.VPlayer atIndex:0];
    }
}

- (void)initSession {
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithDirection:AVCaptureDevicePositionBack] error:nil];
    self.imageOutput = [[AVCaptureStillImageOutput alloc]init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.imageOutput setOutputSettings:outputSettings];
    if ([self.captureSession canAddInput:self.deviceInput]) {
        [self.captureSession addInput:self.deviceInput];
    }
    if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
    }
}

- (AVCaptureDevice *)cameraWithDirection:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

/*
 返回中间框大小
 */
- (CGRect)makeScanReaderInterrestRect {
    CGRect scanRect = CGRectMake(0, 110*ScreenScaleRatio, 300*ScreenScaleRatio, 450*ScreenScaleRatio);
    scanRect.origin.x = MAINSCREEN_BOUNDS.size.width/2 - scanRect.size.width / 2;
    return scanRect;
}

/*
 相机界面
 */
- (UIImageView *)makeScanCameraShadowViewWithRect{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:MAINSCREEN_BOUNDS];
    UIGraphicsBeginImageContext(imgView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.3);
    CGContextFillRect(context, MAINSCREEN_BOUNDS);
    CGContextClearRect(context, [self makeScanReaderInterrestRect]);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    imgView.image = image;
    return imgView;
}

/*
 拍照事件
 */
- (void)takePhotoWithCommit:(void (^)(UIImage *image))commitBlock {
    AVCaptureConnection *vConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    vConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;//控制输出照片方向
    __block UIImage *image;
    if (!vConnection) {
        NSLog(@"failed");
        return ;
    }
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:vConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return ;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        image = [UIImage imageWithData:imageData];
        CGRect rect1 = [self transfromRectWithImageSize:image.size];
        UIGraphicsBeginImageContext(rect1.size);
        CGImageRef subImgeRef = CGImageCreateWithImageInRect(image.CGImage, rect1);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, rect1, subImgeRef);
        image = [UIImage imageWithCGImage:subImgeRef];
        UIGraphicsEndImageContext();
        commitBlock(image);
    }];
}

/*
 比例剪切照片
 */
- (CGRect)transfromRectWithImageSize:(CGSize)size {
    CGRect newRect;
    CGRect clipRect = [self makeScanReaderInterrestRect];
    CGFloat  clipWidth = clipRect.size.width;
    CGFloat  clipHeigth = clipRect.size.height;
    CGFloat  imageH = size.height;
    CGFloat  imageW = size.width;
    CGFloat  vpLayerW = self.bounds.size.width;
    CGFloat  vpLayerH = self.bounds.size.height;
    newRect.size = CGSizeMake(imageW * clipWidth / vpLayerW, imageH * clipHeigth / vpLayerH);
    newRect.origin = CGPointMake((imageW - newRect.size.width)/2, (imageH - newRect.size.height)/2);
    return newRect;
}

- (void)startCamera
{
    if (self.captureSession) {
        [self.captureSession startRunning];
    }
}

- (void)stopCamera {
    if (self.captureSession) {
        [self.captureSession stopRunning];
    }
}

/*
 闪光灯
 */
- (BOOL)isOpenFlash {
    if ([self.captureDevice hasFlash] && [self.captureDevice hasTorch]) {
        if (self.captureDevice.torchMode == AVCaptureTorchModeOff) {
            [self.captureSession beginConfiguration];
            [self.captureDevice lockForConfiguration:nil];
            [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
            [self.captureDevice setFlashMode:AVCaptureFlashModeOn];
            [self.captureDevice unlockForConfiguration];
            return YES;
        }
        else if (self.captureDevice.torchMode == AVCaptureTorchModeOn) {
            [self.captureSession beginConfiguration];
            [self.captureDevice lockForConfiguration:nil];
            [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
            [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
            [self.captureDevice unlockForConfiguration];
            return NO;
        }
        [self.captureSession commitConfiguration];
    }
    return YES;
}

@end
