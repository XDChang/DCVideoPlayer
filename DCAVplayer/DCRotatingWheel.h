//
//  DCRotatingWheel.h
//  自定义滚轮
//
//  Created by XDChang on 17/3/17.
//  Copyright © 2017年 XDChang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCRotatingWheel : UIControl


/*!
 @property value
 @abstract 滚动所改变的值（+ -）
 */

@property (nonatomic, assign) CGFloat value;

/*!
 @property delegate
 @abstract 代理
 */
@property (nonatomic,assign) id delegate;
@end

@protocol DCRotatingWheelDelegate <NSObject>
// 惯性滑动
- (void)onDCRotatingWheelDelegateInertanceEventWithValue:(float)value;

// 惯性滑动已经停止
- (void)onDCRotatingWheelDelegateInertanceDidStop;
@end
