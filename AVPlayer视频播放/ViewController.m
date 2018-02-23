//
//  ViewController.m
//  AVPlayer视频播放
//
//  Created by majianjie on 2018/2/23.
//  Copyright © 2018年 majianjie. All rights reserved.
//我们简单介绍一下这三个属性之间的关系吧

// 1. 首先我们之所以能够看到视频是因为AVPlayerLayer帮我们把视频呈现出来了，可以说是AVPlayerLayer就是一个视频播放器的载体，它负责需要播放的画面。用MVC比喻，就是AVPlayerLayer属于V层，负责对用户的呈现。从AVPlayerLayer的便利构造器方法中可以看出我们在创建一个AVPlayerLayer的时候需要一个AVPlayer类型的参数。所以在创建AVPlayerLayer的时候，我们需要先有一个AVPlayer，它用MVC来分类的话就相当于MVC中的C层，负责播放单元和播放界面的协调工作，我们在它的便利构造器方法中可以看到他需要我们传入一个AVPlayerItem也就是播放单元，所谓的播放单元就是给播放器提供了一个数据的来源，用MVC来类比的话，它就属于M层，在创建一个播放单元的时候，我们首先得需要一个网址。

// 2. 播放进度 CMTime类型一般是用来表示视频或者动画的时间类型。CMTime对象的Value属性是用来得到当前视频或者动画一共有多少帧，timescale指的是每秒多少帧；timescale指的是每秒多少帧，value/timescale = 视频的总时长（秒）


#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@interface ViewController ()

@property (strong, nonatomic)AVPlayer *mPlayer;//播放器
@property (strong, nonatomic)AVPlayerItem *item;//播放单元
@property (strong, nonatomic)AVPlayerLayer *playerLayer;//播放界面（layer）


@property (strong, nonatomic)UISlider *avSlider;//用来现实视频的播放进度，并且通过它来控制视频的快进快退。
@property (assign, nonatomic)BOOL isReadToPlay;//用来判断当前视频是否准备好播放。

@property (nonatomic,strong)NSTimer *timer;

@property (nonatomic,strong)UIButton *replayBtn;
@property (nonatomic,strong)UIButton *stopBtn;
@property (nonatomic,strong)UIButton *captureBtn;


@property (nonatomic,assign)CGFloat startTime;
@property (nonatomic,assign)CGFloat endTime;
@property (nonatomic,assign)CGFloat totalTime;

@property (nonatomic,strong)UITextField *startField;
@property (nonatomic,strong)UITextField *endField;

@property (nonatomic,strong)UILabel *totalTimeLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.startTime = 0.0;
    self.endTime = 0.0;

    [self configPlayer];


}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

- (void)configPlayer{

//   第一步：首先我们需要一个播放的地址
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"vedio.MP4"];
    NSURL *mediaURL = [NSURL fileURLWithPath:path];
    //    第二步：初始化一个播放单元
    self.item = [AVPlayerItem playerItemWithURL:mediaURL];
    //    第三步：初始化一个播放器对象
    self.mPlayer = [AVPlayer playerWithPlayerItem:self.item];
    //第四步：初始化一个播放器的Layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mPlayer];
    self.playerLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height * 0.8);
    [self.view.layer addSublayer:self.playerLayer];
    //第五步：开始播放
    [self.mPlayer play];

    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    CMTime   time = [asset duration];
    self.totalTime = ceil(time.value/time.timescale);

    //通过KVO来观察status属性的变化，来获得播放之前的错误信息
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    [self.view addSubview:self.replayBtn];
    [self.view addSubview:self.stopBtn];
    [self.view addSubview:self.captureBtn];

    [self.view addSubview:self.startField];
    [self.view addSubview:self.endField];
    [self.view addSubview:self.totalTimeLabel];


    [self setTimer];
}

- (void)setTimer{

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(refreshSlideTime) userInfo:nil repeats:YES];

}

//刷新进度时间,进度条
-(void)refreshSlideTime{

    //获取当前视频的播放时长，根据当前的压缩比转换后， 以mm:ss 格式显示在label中
    if (self.isReadToPlay) {
        //获取进度条信息
        double time = self.mPlayer.currentTime.value / self.mPlayer.currentTime.timescale;
        self.avSlider.value = time;
        //当视频结束时，停止定时器并将标志位置为 NO，以便点击play按钮时，可以直接播放视频，但是要注意在slide的事件下处理定时器
        if (self.avSlider.value == self.item.duration.value/self.item.duration.timescale){
            [self.timer invalidate];
            self.replayBtn.enabled = YES;
            self.replayBtn.backgroundColor = [UIColor redColor];

            self.stopBtn.enabled = NO;
            self.stopBtn.backgroundColor = [UIColor grayColor];
        }
    }
}


- (void)playAction{
    if ( self.isReadToPlay) {
        self.avSlider.value = 0;
        [self setTimer];
        CMTime startTime = CMTimeMakeWithSeconds(0, self.item.currentTime.timescale);
        [self.mPlayer seekToTime:startTime completionHandler:^(BOOL finished) {
            if (finished) {
                [self.mPlayer play];
            }
        }];
        _replayBtn.backgroundColor = [UIColor grayColor];
        [_replayBtn setTitle:@"重播" forState:UIControlStateNormal];
        _replayBtn.enabled = NO;

        self.stopBtn.enabled = YES;
        self.stopBtn.backgroundColor = [UIColor greenColor];


    }else{
        NSLog(@"视频正在加载中");
    }
}

- (void)stopAction{

    if (self.isReadToPlay ) {
        self.isReadToPlay = NO;
        [self.mPlayer pause];
        [self.timer invalidate];
    }else{
        self.isReadToPlay = YES;
        [self.mPlayer play];
        [self setTimer];
    }

}

- (void)faildAlert:(NSString *)message{

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];

    [self presentViewController:alertController animated:YES completion:nil];


}

- (void)captureAction{

    self.startTime = [self.startField.text floatValue];
    self.endTime = [self.endField.text floatValue];



    if (self.startTime < 1) {[self faildAlert:@"开始时间必须大于 1"];return;}
    if (self.endTime < 1) {[self faildAlert:@"结束时间必须大于 1"];return;}
    if (self.startTime > self.endTime) {[self faildAlert:@"开始时间必须小于结束时间"];return;}
    if (self.startTime > self.endTime) {[self faildAlert:@"开始时间必须小于结束时间"];return;}
    if(self.startTime  > self.totalTime){[self faildAlert:@"开始时间大于视频总时长"]; return;}
    if(self.endTime  > self.totalTime){[self faildAlert:@"结束时间大于视频总时长"]; return;}
    if((self.endTime - self.startTime) > self.totalTime ){[self faildAlert:@"截取时间大于视频总时长"]; return;}

    self.isReadToPlay = NO;
    [self.mPlayer pause];
    [self.timer invalidate];

    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"vedio.MP4"];
    NSURL *mediaURL = [NSURL fileURLWithPath:path];
    AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:mediaURL options:nil];

    //创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition* mixComposition = [AVMutableComposition composition];


    //开始位置
    CMTime startTime = CMTimeMakeWithSeconds(self.startTime, videoAsset.duration.timescale);
    //结束的位置
    CMTime endTime = CMTimeMakeWithSeconds(self.endTime, videoAsset.duration.timescale);
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, endTime);

    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;

    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
    }

    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
    [compositionVideoTrack setPreferredTransform:assetVideoTrack.preferredTransform];


    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionAudioTrack insertTimeRange:videoTimeRange ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];



    // 创建一个输出
    CMTime acturalDuraton = CMTimeSubtract(endTime, startTime);
    [mixComposition removeTimeRange:CMTimeRangeMake(acturalDuraton, mixComposition.duration)];

    NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tmpFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpFile error:nil];
    }
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:tmpFile];
    session.outputFileType = AVFileTypeQuickTimeMovie;

    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {

            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:session.outputURL];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {

            }];
            [self faildAlert:@"导出成功"];
        }else {
            [self faildAlert:@"导出失败"];
        }
    }];

}

/** 播放方法 */
- (void)playWithUrl:(NSURL *)url{

    // 传入地址
    self.item = [AVPlayerItem playerItemWithURL:url];
    // 播放器
    self.mPlayer = [AVPlayer playerWithPlayerItem:self.item];
    // 播放器layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mPlayer];
    // 视频填充模式
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    // 播放
    [self.mPlayer play];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:
(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        //取出status的新值
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey]intValue];
        switch (status) {
            case AVPlayerItemStatusFailed:
                NSLog(@"item 有误");
                self.isReadToPlay = NO;
                break;
            case AVPlayerItemStatusReadyToPlay:
                NSLog(@"准好播放了");
                self.isReadToPlay = YES;
                self.avSlider.maximumValue = self.item.duration.value / self.item.duration.timescale;
                break;
            case AVPlayerItemStatusUnknown:
                NSLog(@"视频资源出现未知错误");
                self.isReadToPlay = NO;
                break;
            default:
                break;
        }
    }
    //移除监听（观察者）
    [object removeObserver:self forKeyPath:@"status"];
}

- (void)avSliderAction{
    //slider的value值为视频的时间
    float seconds = self.avSlider.value;
    //让视频从指定的CMTime对象处播放。
    CMTime startTime = CMTimeMakeWithSeconds(seconds, self.item.currentTime.timescale);

    [self setTimer];// timer 监听进度

    //让视频从指定处播放
    [self.mPlayer seekToTime:startTime completionHandler:^(BOOL finished) {
        if (finished) {
            [self playAction];
        }
    }];
}


- (UISlider *)avSlider{
    if (!_avSlider) {
        _avSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 30, self.view.bounds.size.width, 30)];
        [_avSlider addTarget:self action:@selector(avSliderAction) forControlEvents:
         UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchUpOutside];

        [self.view addSubview:_avSlider];
    }return _avSlider;
}

- (UIButton *)stopBtn{
    if (!_stopBtn) {
        _stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _stopBtn.frame = CGRectMake(0, self.view.frame.size.height - 72, self.view.frame.size.width, 35);
        _stopBtn.backgroundColor = [UIColor greenColor];
        [_stopBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [_stopBtn addTarget:self action:@selector(stopAction) forControlEvents:UIControlEventTouchUpInside];

    }
    return _stopBtn;
}

- (UIButton *)replayBtn{
    if (!_replayBtn) {
        _replayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _replayBtn.frame = CGRectMake(0, self.view.frame.size.height - 35, self.view.frame.size.width, 35);
        _replayBtn.backgroundColor = [UIColor grayColor];
        [_replayBtn setTitle:@"重播" forState:UIControlStateNormal];
        _replayBtn.enabled = NO;
        [_replayBtn addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];

    }
    return _replayBtn;
}

- (UIButton *)captureBtn{

    if (!_captureBtn) {

        _captureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _captureBtn.frame = CGRectMake(0, self.view.frame.size.height - 108, self.view.frame.size.width, 35);
        _captureBtn.backgroundColor = [UIColor blueColor];
        [_captureBtn setTitle:@"截取视频 并保存" forState:UIControlStateNormal];
        [_captureBtn addTarget:self action:@selector(captureAction) forControlEvents:UIControlEventTouchUpInside];


    }

    return _captureBtn;


}

- (UITextField *)startField{
    if (!_startField) {
        _startField = [[UITextField alloc] initWithFrame:CGRectMake(0, 70, 90, 30)];
        _startField.keyboardType = UIKeyboardTypeNumberPad;
        _startField.placeholder= @"输入开始时间";
        _startField.textColor = [UIColor whiteColor];
        _startField.font = [UIFont systemFontOfSize:14];
        _startField.textAlignment = NSTextAlignmentCenter;
        _startField.backgroundColor = [UIColor grayColor];
    }
    return _startField;
}

- (UITextField *)endField{
    if (!_endField) {
        _endField = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 90, 70, 90, 30)];
        _endField.keyboardType = UIKeyboardTypeNumberPad;
        _endField.placeholder= @"输入结束时间";
        _endField.textColor = [UIColor whiteColor];
        _endField.textAlignment = NSTextAlignmentCenter;
        _endField.font = [UIFont systemFontOfSize:14];
        _endField.backgroundColor = [UIColor grayColor];
    }
    return _endField;

}

- (UILabel *)totalTimeLabel{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(95, 70, self.view.frame.size.width - 180 - 10, 30)];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        _totalTimeLabel.backgroundColor = [UIColor greenColor];
        _totalTimeLabel.textColor = [UIColor redColor];
        _totalTimeLabel.text = [NSString stringWithFormat:@"视频总时长 : %.f 秒",self.totalTime];
    }
    return _totalTimeLabel;
}


@end
