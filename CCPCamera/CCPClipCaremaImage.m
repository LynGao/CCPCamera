//
//  CCPClipCaremaImage.m
//  QHPay
//
//  Created by liqunfei on 16/3/15.
//  Copyright © 2016年 chenlizhu. All rights reserved.
//

#import "CCPClipCaremaImage.h"
#import <AVFoundation/AVFoundation.h>

@interface CCPClipCaremaImage()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic,strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *VPlayer;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic,strong) AVCaptureVideoDataOutput *metadaOutput;
@end

@implementation CCPClipCaremaImage

- (instancetype)initWithFrame:(CGRect)frame andFunction:(NSString *)function {
    if (self = [super initWithFrame:frame]) {
        [self setUpCameraPreviewLayerWithFunction:function];
        if ([function isEqualToString:@"camera"]) {
            [self addSubview:[self makeScanCameraShadowViewWithRectWithRed:0 Green:0 Blue:0 Alpha:0.3]];
        }
        else if ([function isEqualToString:@"face"]) {
            [self addSubview:[self makeScanCameraShadowViewWithRectWithRed:82 Green:172 Blue:205 Alpha:0.3]];
        }
        
    }
    return self;
}

- (void)setUpCameraPreviewLayerWithFunction:(NSString *)function {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        return;
    }
    if (!_VPlayer) {
        [self initSessionWithFunction:function];
        self.VPlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        self.VPlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.VPlayer.position = self.center;
        self.VPlayer.bounds = self.bounds;
        [self.layer insertSublayer:self.VPlayer atIndex:0];
    }
}

- (void)initSessionWithFunction:(NSString *)function {
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    self.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithDirection:AVCaptureDevicePositionBack] error:nil];
    if ([self.captureSession canAddInput:self.deviceInput]) {
        [self.captureSession addInput:self.deviceInput];
    }
    if ([function isEqualToString:@"camera"]) {
        self.imageOutput = [[AVCaptureStillImageOutput alloc]init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
        [self.imageOutput setOutputSettings:outputSettings];
        if ([self.captureSession canAddOutput:self.imageOutput]) {
            [self.captureSession addOutput:self.imageOutput];
        }
    }
    else if ([function isEqualToString:@"face"]) {
        self.metadaOutput = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t cameraQueue = dispatch_queue_create( "caremaQueue", DISPATCH_QUEUE_SERIAL);
        [self.metadaOutput setSampleBufferDelegate:self queue:cameraQueue];
        self.metadaOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        if ([self.captureSession canAddOutput:self.metadaOutput]) {
            [self.captureSession addOutput:self.metadaOutput];
        }
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef cvImg = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(cvImg, 0);
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(cvImg, 0);
    size_t bytePerRow = CVPixelBufferGetBytesPerRow(cvImg);
    size_t width = CVPixelBufferGetWidth(cvImg);
    size_t height = CVPixelBufferGetHeight(cvImg);
    size_t perComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst;
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, perComponent, bytePerRow, colorSpace, bitmapInfo);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight];
    CIContext *ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}];
    CIDetector *cidetector = [CIDetector detectorOfType:CIDetectorTypeFace context:ciContext options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}] ;
    CIImage *ciImg = [[CIImage alloc] initWithImage:image];
    NSArray *results = [cidetector featuresInImage:ciImg options:@{CIDetectorImageOrientation:@(6)}];
    for (id object in results) {
        if ([object isKindOfClass:[CIFaceFeature class]]) {
            CIFaceFeature *faceFeature = (CIFaceFeature *)object;
            UIView *view = [[UIView alloc] initWithFrame:faceFeature.bounds];
            view.layer.borderColor = [UIColor orangeColor].CGColor;
            view.layer.borderWidth = 2;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addSubview:view];
                [self bringSubviewToFront:view];
            });
           // UIImage *faceImg = [UIImage imageWithCGImage:[ciContext createCGImage:ciImg fromRect:faceFeature.bounds] scale:1.0 orientation:UIImageOrientationRight];
            NSLog(@"face found at (%f,%f) of dimensions %fx%f",faceFeature.bounds.origin.x,faceFeature.bounds.origin.y,[self makeScanReaderInterrestRect].origin.x,[self makeScanReaderInterrestRect].origin.y);
        }
    }
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
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
- (UIImageView *)makeScanCameraShadowViewWithRectWithRed:(CGFloat)r Green:(CGFloat)g Blue:(CGFloat)b Alpha:(CGFloat)a{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:MAINSCREEN_BOUNDS];
    UIGraphicsBeginImageContext(imgView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, r, g, b, a);
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
