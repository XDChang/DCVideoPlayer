//
//  DCRotatingWheel.m
//  自定义滚轮
//
//  Created by XDChang on 17/3/17.
//  Copyright © 2017年 XDChang. All rights reserved.
//

#import "DCRotatingWheel.h"

#define LineCounts 15.0
@interface DCRotatingWheel ()
{
    CGFloat _kRadius;                  // 半径（滚轮长度的一般）
    CGFloat _layerLength;              // 线条长度（滚轮高度减20）
    double _intervalTwoLine;           // 两条线之间的弧度（15/π）
    CGPoint _lastTouchPoint;           // 上次触碰点（每次触摸、滑动都要记录）
    CGFloat _scroledRange;             // 滚动的距离（默认为0）
}

@property (nonatomic,copy) NSMutableArray *linesArray; // 线条layer开始点的集合

@end

@implementation DCRotatingWheel


- (id)initWithFrame:(CGRect)frame
{

    self = [super initWithFrame:frame];
    
    if (self) {
        
        [self initAll];
    }

    return self;
}

#pragma mark --- initAll

- (void)initAll
{
    self.layer.cornerRadius = 5;
    
    self.backgroundColor = [UIColor colorWithRed:184/255.0
                                           green:184/255.0
                                            blue:184/255.0 alpha:1];
    
    _kRadius =self.frame.size.width/2.0;
    
    _layerLength = self.frame.size.height-20;
    
    _intervalTwoLine = M_PI/LineCounts;
    
    _linesArray = [[NSMutableArray alloc]init];
    
    _scroledRange = 0.0f;
    
    [self resetLinesArray];
    [self.layer setNeedsDisplay];

}


#pragma mark --- 核心代码
/*!
 @method  每条线初始点的集合。
 @abstract 初始化每条的初始位置点，并记录下来。
 @discussion 利用三角函数，反三角函数，将滚轮滑动的距离转换为弧度，并计算出每条线的初始点。

 */
- (void)resetLinesArray
{
    [_linesArray removeAllObjects];
    
    double arcTheLine = asin((_kRadius - _scroledRange)/ (_kRadius));

    for (int i = 0; i < (LineCounts +1); i++) {
        
        double temArc =arcTheLine - i *_intervalTwoLine ;
        
        if (temArc < 0) {
            
            temArc += M_PI;
        }
        
        CGPoint pt;
        // 加π的原因是 滚轮转动的方向跟滑动方向相反，故加上π调整过来。
        pt.x = _kRadius - _kRadius*cos(temArc+M_PI);

        pt.y = (_layerLength * 0.5 + _layerLength* 0.5*sin(temArc+M_PI));
        
        [_linesArray addObject:[NSValue valueWithCGPoint:pt]];
        
    }

}
/*!
 @method  画出每条刻度线。
 @abstract 利用CGContext 画出每条刻度线。
 @discussion 根据三角函数算出的点，转换成长短不一，距离不一的刻度线。
 @param layer layer 图层
 @param ctx 上下文
 
 */
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{

    if (layer == self.layer) {
        
        for (NSValue *num in _linesArray) {
            
            
            CGPoint pt = [num CGPointValue];
            
            double y = pt.y;
            
            double x = pt.x;
            
            //加10的原因是：最长线条是滚轮宽度减20，所以加上10，以达到刻度线居中的目的。
            CGContextMoveToPoint(ctx, x, y+10);
            CGContextAddLineToPoint(ctx,x,_layerLength+10 - y);
            CGContextClosePath(ctx);
            CGContextSetLineWidth(ctx, 1);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGContextSetStrokeColorWithColor(ctx,[UIColor whiteColor].CGColor);
            CGContextStrokePath(ctx);
            
        }
    }
}
/*!
 @method  重写control的系统方法。
 @abstract control开始触碰。
 @discussion 开始触碰滚轮的方法,记录下触碰点。
 @param touch 触碰点
 @param event 事件
 @result 返回布尔值
 */
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _lastTouchPoint = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.layer.bounds, _lastTouchPoint)) {
        
        
        [self.layer setNeedsDisplay];
        
        return YES;
        
    }
    return NO;
}
/*!
 @method  重写control的系统方法。
 @abstract control持续触碰。
 @discussion 持续触碰滚轮的方法，根据触碰点计算滚动距离。
 @param touch 触碰点
 @param event 事件
 @result 返回布尔值
 */
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{

    CGPoint pt = [touch locationInView:self];
    
    CGFloat temLength = pt.x - _lastTouchPoint.x;
    
    float radiuDelta = temLength/_kRadius;
    
    self.value = temLength;
    
    _scroledRange += temLength;
    
    NSLog(@"aaa==%f",temLength);
    
    _lastTouchPoint = pt;
    
  
    if (_scroledRange < 0) {
        
        _scroledRange =_kRadius + _scroledRange;
    }
    if (_scroledRange > _kRadius) {
        
        _scroledRange =_scroledRange - _kRadius;
    }
    
    // 有效滚动才重置layer
    if (radiuDelta != 0) {
        
        [self resetLinesArray];
        [self.layer setNeedsDisplay];
    }
    // 设置触发事件
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    return YES;
}
/*!
 @method  重写control的系统方法。
 @abstract control结束触碰。
 @discussion 结束触碰滚轮的方法。
 @param touch 触碰点
 @param event 事件

 */
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self.layer setNeedsDisplay];
    // 设置触发事件
    [self sendActionsForControlEvents:UIControlEventValueChanged];

}

@end
