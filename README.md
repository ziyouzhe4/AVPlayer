# AVPlayer
### 主要功能: 载入一个本地的视频, 然后截取其中 任意时间段的内容,保存到相册.

> CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b
    CMTimeMakeWithSeconds(a,b)    a 当前时间,b 每秒钟多少帧.

    CMTimeMake顾名思义就是用来建立CMTime用的,
    但是千万别误会他是拿來用在一般时间用的,
    CMTime可是专门用來表示影片时间用的類別,
    他的用法为: CMTimeMake(time, timeScale)

    time指的就是时间(不是秒),
    而时间要换算成秒就要看第二個参数timeScale了.
    timeScale指的是1秒需要由几个frame组成(可以视为fps),
    因此真正要表达的时间就會是 time / timeScale 才会是秒.

 举个例子:

    CMTimeMake(60, 30);
    CMTimeMake(30, 15);
    在这两个例子中所表达在影片中的时间都为2秒钟,
    但是影隔播放速速率不同, 相差了有兩倍.


```swift
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
    
```

```swift
// 创建一个输出
    // AVAssetExportSession 用于合并你采集的视频和音频，最终会保存为一个新文件，可以设置文件的输出类型、路径，以及合并的一个状态
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
```
