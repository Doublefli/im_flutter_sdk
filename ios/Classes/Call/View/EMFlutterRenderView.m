//
//  EMFlutterRenderView.m
//  im_flutter_sdk
//
//  Created by 杜洁鹏 on 2020/10/20.
//

#import "EMFlutterRenderView.h"
#import <Hyphenate/Hyphenate.h>

@interface EMFlutterRenderView ()
{
    UIView *_iOSView;
}
@end

@implementation EMFlutterRenderView

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id)args
                    messenger:(nonnull NSObject <FlutterBinaryMessenger> *)messager
                     viewType:(EMFlutterRenderViewType)viewType {
    if (self = [super init]) {
        switch (viewType) {
            case Local:
                [self createLocalView:frame
                       viewIdentifier:viewId
                            arguments:args];
                break;
            case Remote:
                [self createRemoteView:frame
                        viewIdentifier:viewId
                             arguments:args];
                break;
            default:
                break;
        }
        
    }
    return self;
}

- (void)createLocalView:(CGRect)frame
         viewIdentifier:(int64_t)viewId
              arguments:(id)args
{
    EMCallLocalVideoView *localView = [[EMCallLocalVideoView alloc] initWithFrame:frame];
    localView.scaleMode = EMCallViewScaleModeAspectFill;
    _iOSView = localView;
}

- (void)createRemoteView:(CGRect)frame
          viewIdentifier:(int64_t)viewId
               arguments:(id)args
{
    EMCallRemoteVideoView *remoteView = [[EMCallRemoteVideoView alloc] initWithFrame:frame];
    remoteView.scaleMode = EMCallViewScaleModeAspectFill;
    _iOSView = remoteView;
}

- (UIView *)previewView {
    return _iOSView;
}

#pragma mark - FlutterPlatformView
- (nonnull UIView *)view {
    return _iOSView;
}




@end
