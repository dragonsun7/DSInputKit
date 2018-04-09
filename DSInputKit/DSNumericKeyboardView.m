//
//  DSNumericKeyboardView.m
//  DSInputKitDemo
//
//  Created by Dragon Sun on 2018/03/29.
//  Copyright © 2018 Dragon Sun. All rights reserved.
//

#import "DSNumericKeyboardView.h"

#define RGBA(r, g, b, a)    \
    ([UIColor colorWithRed:(r) / 255.f green:(g) / 255.f blue:(b) / 255.f alpha:(a)])
#define SCREEN_WIDTH        \
    [UIScreen mainScreen].bounds.size.width

#define VIEW_BACKGROUND_COLOR    (RGBA(204.f, 204.f, 204.f, 1.f))   // 键盘视图底色(也就是分割线的颜色)
#define BUTTON_NORMAL_COLOR      (RGBA(250.f, 250.f, 250.f, 1.f))   // 一般按钮的NormalColor
#define DONE_BUTTON_NORMAL_COLOR (RGBA(0.f, 170.f, 238.f, 1.f))     // 确定按钮的NormalColor
#define BUTTON_FONT_COLOR        ([UIColor blackColor])             // 字体颜色
#define DONE_BUTTON_FONT_COLOR   ([UIColor whiteColor])             // 确定按钮字体颜色
static NSInteger const kButtonCount     = 16;                       // 按钮数量
static NSInteger const kTagZero         =  0;                       // 按钮0的tag值
static NSInteger const kTagDot          = 10;                       // 小数点按钮的tag值
static NSInteger const kTagX            = 11;                       // X按钮的tag值
static NSInteger const kTagPlaceHolder  = 12;                       // 占位按钮(数字键盘时使用)
static NSInteger const kTagDismiss      = 13;                       // 收起键盘按钮的tag值
static NSInteger const kTagBackspace    = 14;                       // 删除按钮的tag值
static NSInteger const kTagDone         = 15;                       // 确定按钮的tag值
static NSInteger const kRowCount        = 4;                        // 按钮的行数
static NSInteger const kColCount        = 4;                        // 按钮的列数
static CGFloat   const kButtonHeight    = 60.f;                     // 按钮的高度
static CGFloat   const kSplitLineWidth  = 0.5f;                     // 分割线的宽度
static CGFloat   const kDeltaBrightness = -0.1f;                    // 默认HighLighted颜色的亮度相对差异值
static CGFloat   const kDeltaAlpha      = -0.4f;                    // 确认按钮Disable时，文字的透明度相对差异值
static CGFloat   const kFontSize        = 25.f;                     // 按钮字体大小
static NSString *const kFontName        = @"HelveticaNeue";         // 按钮字体名称
static NSString *const kTitleDot        = @".";                     // 小数点按钮title
static NSString *const kTitleX          = @"X";                     // X按钮title
static NSString *const kTitleDone       = @"确定";                   // 确定按钮title
static double    const kRepeatInterval  = 0.1f;                     // 长按时，重复的间隔时间(秒)
static double    const kRepeatOverDelay = 2.f;                      // 长按设定的时间后，会删除光标前所有的字符


/* ==================== UIColor ==================== */

@interface UIColor (Brightness)

// 修改颜色亮度
- (instancetype)colorWithDeltaBrightness:(CGFloat)deltaBrightness;

// 修改颜色透明度
- (instancetype)colorWithDeltaAlpha:(CGFloat)deltaAlpha;

@end

@implementation UIColor (Brightness)

- (instancetype)colorWithDeltaBrightness:(CGFloat)deltaBrightness {
    CGFloat hud, saturation, brightness, alpha;
    [self getHue:&hud saturation:&saturation brightness:&brightness alpha:&alpha];
    
    return [UIColor colorWithHue:hud saturation:saturation brightness:brightness + deltaBrightness alpha:alpha];
}

- (instancetype)colorWithDeltaAlpha:(CGFloat)deltaAlpha {
    CGFloat hud, saturation, brightness, alpha;
    [self getHue:&hud saturation:&saturation brightness:&brightness alpha:&alpha];
    
    return [UIColor colorWithHue:hud saturation:saturation brightness:brightness alpha:alpha + deltaAlpha];
}

@end


/* ==================== UIImage ==================== */

@interface UIImage (Creation)

// 生成纯色颜色图片
+ (instancetype)imageWithColor:(UIColor *)color size:(CGSize)size;

@end

@implementation UIImage(Creation)

+ (instancetype)imageWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0.f, 0.f, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end


/* ==================== UIButton ==================== */

@interface UIButton (BackgroundColor)

// 设置按钮背景色
- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state;

@end

@implementation UIButton (BackgroundColor)

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state {
    UIImage *image = [UIImage imageWithColor:backgroundColor size:CGSizeMake(1.f, 1.f)];
    [self setBackgroundImage:image forState:state];
}

@end


/* ==================== UIView ==================== */

@interface UIView (FirstResponder)

// 查找第一响应者
- (UIView<UITextInput> *)findFirstResponder;

@end

@implementation UIView (FirstResponder)

- (UIView<UITextInput> *)findFirstResponder {
    if (self.isFirstResponder && [self conformsToProtocol:@protocol(UIKeyInput)])
        return (UIView<UITextInput> *)self;
    
    for (UIView *view in self.subviews) {
        UIView<UITextInput> *responder = [view findFirstResponder];
        if (responder) return responder;
    }
    
    return nil;
}

@end


/* ==================== UIApplication ==================== */

@interface UIApplication (FirstResponder)

// 获取当前应用中的第一响应者
+ (UIView<UITextInput> *)firstResponder;

@end

@implementation UIApplication (FirstResponder)

+ (UIView<UITextInput> *)firstResponder {
    return [[UIApplication sharedApplication].keyWindow findFirstResponder];
}

@end


/* ==================== DSNumericKeyboardView ==================== */

@interface DSNumericKeyboardView() <UIInputViewAudioFeedback> {
    NSTimer *_longPressTimer;
    NSDate *_longPressBeginDate;
}

@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;

@end


@implementation DSNumericKeyboardView

@synthesize keyboardType = _keyboardType;

#pragma mark - Life Cycle

- (instancetype)initWithType:(DSKeyboardType)keyboardType {
    return [self initWithType:keyboardType accessoryView:nil];
}

- (instancetype)initWithType:(DSKeyboardType)keyboardType accessoryView:(nullable UIView *)accessoryView {
    if (self = [super initWithFrame:CGRectZero]) {
        _keyboardType = keyboardType;
        _accessoryView = accessoryView;
        
        // 监听第一响应者文字改变通知(改变确认按钮Disabled状态)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responderTextChanged:) name:UITextFieldTextDidChangeNotification object:[UIApplication firstResponder]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responderTextChanged:) name:UITextViewTextDidChangeNotification object:[UIApplication firstResponder]];
        
        [self initialized];
    }
    
    return self;
}

- (void)dealloc {
    [self cleanTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _accessoryView.frame = CGRectMake(0.f, 0.f, self.frame.size.width, _accessoryView.frame.size.height);

    for (UIButton *button in _buttons) {
        button.frame = [self buttonFrameByIndex:[_buttons indexOfObject:button]];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    
    // 设置确定按钮初始状态
    [self responderTextChanged:nil];
    
    // 设置按钮顺序
    if (_isRandomNumericOrder) [self shuffleNumericButton];
}

#pragma mark - Property

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor {
    _viewBackgroundColor = viewBackgroundColor;
    self.backgroundColor = viewBackgroundColor;
}

- (void)setButtonNormalColor:(UIColor *)buttonNormalColor {
    _buttonNormalColor = buttonNormalColor;
    [self configButtons];
}

- (void)setButtonHighLightedColor:(UIColor *)buttonHighLightedColor {
    _buttonHighLightedColor = buttonHighLightedColor;
    [self configButtons];
}

- (void)setButtonFontColor:(UIColor *)buttonFontColor {
    _buttonFontColor = buttonFontColor;
    [self configButtons];
}

- (void)setDoneButtonNormalColor:(UIColor *)doneButtonNormalColor {
    _doneButtonNormalColor = doneButtonNormalColor;
    [self configButtons];
}

- (void)setDoneButtonDisabledColor:(UIColor *)doneButtonDisabledColor {
    _doneButtonDisabledColor = doneButtonDisabledColor;
    [self configButtons];
}

- (void)setDoneButtonHighLightedColor:(UIColor *)doneButtonHighLightedColor {
    _doneButtonHighLightedColor = doneButtonHighLightedColor;
    [self configButtons];
}

- (void)setDoneButtonFontColor:(UIColor *)doneButtonFontColor {
    _doneButtonFontColor = doneButtonFontColor;
    [self configButtons];
}

- (void)setDoneButtonDisabledFontColor:(UIColor *)doneButtonDisabledFontColor {
    _doneButtonDisabledFontColor = doneButtonDisabledFontColor;
    [self configButtons];
}

- (void)setDoneButtonTitle:(NSString *)doneButtonTitle {
    _doneButtonTitle = doneButtonTitle;
    [self configButtons];
}

- (void)setButtonFont:(UIFont *)buttonFont {
    _buttonFont = buttonFont;
    [self configButtons];
}

#pragma mark - Default Value Method

+ (UIColor *)defaultViewBackgroundColor {
    return VIEW_BACKGROUND_COLOR;
}

+ (UIColor *)defaultButtonNormalColor {
    return BUTTON_NORMAL_COLOR;
}

+ (UIColor *)defaultButtonHighLightedColor {
    return [BUTTON_NORMAL_COLOR colorWithDeltaBrightness:kDeltaBrightness];
}

+ (UIColor *)defaultButtonFontColor {
    return BUTTON_FONT_COLOR;
}

+ (UIColor *)defaultDoneButtonNormalColor {
    return DONE_BUTTON_NORMAL_COLOR;
}

+ (UIColor *)defaultDoneButtonDisabledColor {
    return [self defaultDoneButtonNormalColor];
}

+ (UIColor *)defaultDoneButtonHighLightedColor {
    return [DONE_BUTTON_NORMAL_COLOR colorWithDeltaBrightness:kDeltaBrightness];
}

+ (UIColor *)defaultDoneButtonFontColor {
    return DONE_BUTTON_FONT_COLOR;
}

+ (UIColor *)defaultDoneButtonDisabledFontColor {
    return [DONE_BUTTON_FONT_COLOR colorWithDeltaAlpha:kDeltaAlpha];
}

+ (NSString *)defaultDoneButtonTitle {
    return kTitleDone;
}

+ (NSString *)defaultButtonFontName {
    return kFontName;
}

+ (CGFloat)defaultButtonFontSize {
    return kFontSize;
}

#pragma mark - Actions

- (IBAction)buttonAction:(UIButton *)button {
    [[UIDevice currentDevice] playInputClick];

    // 点击了收起键盘按钮
    if (kTagDismiss == button.tag) {
        [[UIApplication firstResponder] resignFirstResponder];
        return;
    }

    // 点击了确认按钮
    if (kTagDone == button.tag) {
        if ([self shouldReturn]) {
            [[UIApplication firstResponder] resignFirstResponder];
            if (self.done) self.done();
        }
        return;
    }
    
    // 点击了其它按钮
    UIView<UITextInput> *firstResponder = [UIApplication firstResponder];
    if (firstResponder) {
        if (kTagBackspace == button.tag) {
            if ([self shouldChangeText:@""]) {
                [firstResponder deleteBackward];
            }
        } else {
            NSString *text = [self buttonTitleByTag:button.tag];
            if ([self shouldChangeText:text]) {
                [firstResponder insertText:text];
            }
        }
    }
}

- (IBAction)backspaceLongPressAction:(UILongPressGestureRecognizer *)gesture {
    UIButton *button = [self viewWithTag:kTagBackspace];
    if (UIGestureRecognizerStateBegan == gesture.state) {
        dispatch_async(dispatch_get_main_queue(), ^{
            button.highlighted = YES;
        });

        _longPressBeginDate = [NSDate date];
        _longPressTimer = [NSTimer scheduledTimerWithTimeInterval:kRepeatInterval target:self selector:@selector(backspaceTimerAction:) userInfo:nil repeats:YES];
    }
    
    if (UIGestureRecognizerStateEnded == gesture.state
        || UIGestureRecognizerStateCancelled == gesture.state
        || UIGestureRecognizerStateFailed == gesture.state)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            button.highlighted = NO;
        });
        
        [self cleanTimer];
    }
}

- (IBAction)backspaceTimerAction:(id)sender {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_longPressBeginDate];
    if (interval >= kRepeatOverDelay) {
        // 长按回退键一定的时间，会清除之前的所有字符
        [self cleanTimer];
        [self clearTextBeforeCursor];
    } else {
        [(UIControl *)[self viewWithTag:kTagBackspace] sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (IBAction)responderTextChanged:(NSNotification *)notification {
    UIView<UITextInput> *input = [UIApplication firstResponder];
    ((UIButton *)[self viewWithTag:kTagDone]).enabled = input.hasText;
}

# pragma mark - Private

- (void)cleanTimer {
    [_longPressTimer invalidate];
    _longPressTimer = nil;
}

// 初始设置
- (void)initialized {
    // 设置默认值
    self.viewBackgroundColor = [[self class] defaultViewBackgroundColor];
    _buttonNormalColor = [[self class] defaultButtonNormalColor];
    _buttonHighLightedColor = [[self class] defaultButtonHighLightedColor];
    _buttonFontColor = [[self class] defaultButtonFontColor];
    _doneButtonNormalColor = [[self class] defaultDoneButtonNormalColor];
    _doneButtonDisabledColor = [[self class] defaultDoneButtonDisabledColor];
    _doneButtonHighLightedColor = [[self class] defaultDoneButtonHighLightedColor];
    _doneButtonFontColor = [[self class] defaultDoneButtonFontColor];
    _doneButtonDisabledFontColor = [[self class] defaultDoneButtonDisabledFontColor];
    _doneButtonTitle = [[self class] defaultDoneButtonTitle];
    _buttonFont = [UIFont fontWithName:[[self class] defaultButtonFontName] size:[[self class] defaultButtonFontSize]];

    // 创建以及其它设置
    if (_accessoryView) [self addSubview:_accessoryView];
    self.frame = [self viewFrame];
    self.buttons = [self createButtons];
    [self configButtons];
}

// 创建按钮
- (NSMutableArray<UIButton *> *)createButtons {
    NSMutableArray<UIButton *> *arr = [NSMutableArray arrayWithCapacity:kButtonCount];
    for (NSInteger i = 0; i < kButtonCount; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.enabled = [self buttonEnabledByTag:i];
        button.hidden = ![self buttonVisibledByTag:i];
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        if (kTagBackspace == i) {
            UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backspaceLongPressAction:)];
            [button addGestureRecognizer:gesture];
        }
        [arr addObject:button];
        [self addSubview:button];
    }
    
    return arr;
}

// 设置按钮
- (void)configButtons {
    for (UIButton *button in _buttons) {
        button.titleLabel.font = _buttonFont;
        [button setTitleColor:[self buttonTitleNormalColorByTag:button.tag] forState:UIControlStateNormal];
        [button setTitleColor:[self buttonTitleDisabledColorByTag:button.tag] forState:UIControlStateDisabled];
        [button setTitle:[self buttonTitleByTag:button.tag] forState:UIControlStateNormal];
        [button setImage:[self buttonImageByTag:button.tag] forState:UIControlStateNormal];
        [button setBackgroundColor:[self buttonNormalColorByTag:button.tag] forState:UIControlStateNormal];
        [button setBackgroundColor:[self buttonDisabledColorByTag:button.tag] forState:UIControlStateDisabled];
        [button setBackgroundColor:[self buttonHighLightedColorByTag:button.tag] forState:UIControlStateHighlighted];
    }
}

// 随机打乱数字按钮顺序(数组中第0到9元素的顺序)
- (void)shuffleNumericButton {
    for (uint32_t i = kTagZero; i < kTagDot - 1; i++) {
        uint32_t random = arc4random_uniform(kTagDot - i);
        [_buttons exchangeObjectAtIndex:random + i withObjectAtIndex:i];
    }
}

// 获取键盘frame
- (CGRect)viewFrame {
    CGFloat h = _accessoryView ? _accessoryView.frame.size.height : 0.f;
    h += (kButtonHeight + kSplitLineWidth) * kRowCount;  // 纵向是4根分割线
    
    return CGRectMake(0.f, 0.f, SCREEN_WIDTH, h);
}

// 获取按钮位置和大小
- (CGRect)buttonFrameByIndex:(NSInteger)index {
    // 单位位置和大小(对于非数字按钮，index与tag值始终相同)
    CGRect layoutRect;
    switch (index) {
        case kTagPlaceHolder:
        case kTagDot:
        case kTagX:
            layoutRect = CGRectMake(0, 3, 1, 1);
            break;
        case kTagZero:
            layoutRect = CGRectMake(1, 3, 1, 1);
            break;
        case kTagDismiss:
            layoutRect = CGRectMake(2, 3, 1, 1);
            break;
        case kTagBackspace:
            layoutRect = CGRectMake(3, 0, 1, 2);
            break;
        case kTagDone:
            layoutRect = CGRectMake(3, 2, 1, 2);
            break;
        default:
            layoutRect = CGRectMake((index - 1) % 3, (index - 1) / 3, 1, 1);
    }
    
    // 按钮frame
    CGFloat buttonWidth = (SCREEN_WIDTH - kSplitLineWidth * (kColCount - 1)) / kColCount;   // 横向是3根分割线
    CGFloat x = (buttonWidth + kSplitLineWidth) * layoutRect.origin.x;
    CGFloat y = _accessoryView ? _accessoryView.frame.size.height : 0.f;
    y += (kButtonHeight + kSplitLineWidth) * layoutRect.origin.y + kSplitLineWidth;
    if (kTagDone == index) y -= kSplitLineWidth;
    CGFloat w = buttonWidth * layoutRect.size.width + kSplitLineWidth * (layoutRect.size.width - 1);
    CGFloat h = kButtonHeight * layoutRect.size.height + kSplitLineWidth * (layoutRect.size.height - 1);
    return CGRectMake(x, y, w, h);
}

// 获取按钮激活状态
- (BOOL)buttonEnabledByTag:(NSInteger)tag {
    return (kTagPlaceHolder == tag) ? NO : YES;
}

// 获取按钮显示状态
- (BOOL)buttonVisibledByTag:(NSInteger)tag {
    if (kTagPlaceHolder == tag) {
        return DSKeyboardTypeNumber == _keyboardType;
    }
    
    if (kTagDot == tag) {
        return DSKeyboardTypeDecimal == _keyboardType;
    }
    
    if (kTagX == tag) {
        return DSKeyboardTypeIDCard == _keyboardType;
    }
    
    return YES;
}

// 获取Normal状态按钮文字颜色
- (UIColor *)buttonTitleNormalColorByTag:(NSInteger)tag {
    return (kTagDone == tag) ? _doneButtonFontColor : _buttonFontColor;
}

// 获取Disabled状态按钮文字颜色
- (UIColor *)buttonTitleDisabledColorByTag:(NSInteger)tag {
    return (kTagDone == tag) ? _doneButtonDisabledFontColor : _buttonFontColor;
}

// 获取按钮文字
- (NSString *)buttonTitleByTag:(NSInteger)tag {
    switch (tag) {
        case kTagPlaceHolder: return nil;
        case kTagDot        : return (DSKeyboardTypeDecimal == _keyboardType) ? kTitleDot : nil;
        case kTagX          : return (DSKeyboardTypeIDCard == _keyboardType) ? kTitleX : nil;
        case kTagDone       : return _doneButtonTitle;
        case kTagDismiss    : return nil;
        case kTagBackspace  : return nil;
        default:
            return [@(tag) stringValue];
    }
}

// 获取按钮图片
- (UIImage *)buttonImageByTag:(NSInteger)tag {
    if (kTagBackspace == tag) return [self backspaceImageWithColor:[self buttonTitleNormalColorByTag:tag]];
    if (kTagDismiss   == tag) return [self dismissImageWithColor:[self buttonTitleNormalColorByTag:tag]];
    return nil;
}

// 获取按钮Normal状态背景色
- (UIColor *)buttonNormalColorByTag:(NSInteger)tag {
    return (kTagDone == tag) ? _doneButtonNormalColor : _buttonNormalColor;
}

// 获取按钮Disabled状态背景颜色
- (UIColor *)buttonDisabledColorByTag:(NSInteger)tag {
    return (kTagDone == tag) ? _doneButtonDisabledColor : _buttonNormalColor;
}

// 获取按钮HighLighted状态背景色
- (UIColor *)buttonHighLightedColorByTag:(NSInteger)tag {
    return (kTagDone == tag) ? _doneButtonHighLightedColor : _buttonHighLightedColor;
}

// 绘制Backspace图标
- (UIImage *)backspaceImageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat lineWidth = 1.f * scale;
    CGSize size = CGSizeMake(27.f * scale, 20.f * scale);
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setStroke];

    CGContextBeginPath(context);
    
    // 绘制边
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(8.5 * scale, 19.5 * scale)];
    [bezierPath addCurveToPoint: CGPointMake(23.15 * scale, 19.50 * scale)
                  controlPoint1: CGPointMake(11.02 * scale, 19.50 * scale)
                  controlPoint2: CGPointMake(20.63 * scale, 19.50 * scale)];
    [bezierPath addCurveToPoint: CGPointMake(26.50 * scale, 15.50 * scale)
                  controlPoint1: CGPointMake(25.66 * scale, 19.50 * scale)
                  controlPoint2: CGPointMake(26.50 * scale, 17.50 * scale)];
    [bezierPath addCurveToPoint: CGPointMake(26.50 * scale,  4.50 * scale)
                  controlPoint1: CGPointMake(26.50 * scale, 13.50 * scale)
                  controlPoint2: CGPointMake(26.50 * scale,  7.50 * scale)];
    [bezierPath addCurveToPoint: CGPointMake(23.15 * scale,  0.50 * scale)
                  controlPoint1: CGPointMake(26.50 * scale,  1.50 * scale)
                  controlPoint2: CGPointMake(24.82 * scale,  0.50 * scale)];
    [bezierPath addCurveToPoint: CGPointMake( 8.50 * scale,  0.50 * scale)
                  controlPoint1: CGPointMake(21.47 * scale,  0.50 * scale)
                  controlPoint2: CGPointMake(11.02 * scale,  0.50 * scale)];
    [bezierPath addCurveToPoint: CGPointMake( 0.50 * scale,  9.50 * scale)
                  controlPoint1: CGPointMake( 5.98 * scale,  0.50 * scale)
                  controlPoint2: CGPointMake( 0.50 * scale,  9.50 * scale)];
    [bezierPath addCurveToPoint: CGPointMake( 8.50 * scale, 19.50 * scale)
                  controlPoint1: CGPointMake( 0.50 * scale,  9.50 * scale)
                  controlPoint2: CGPointMake( 5.98 * scale, 19.50 * scale)];
    [bezierPath closePath];
    bezierPath.lineCapStyle = kCGLineCapRound;
    bezierPath.lineJoinStyle = kCGLineJoinRound;
    bezierPath.lineWidth = lineWidth;
    [bezierPath stroke];
    
    // 画中间的X
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(19.5 * scale, 6.5 * scale)];
    [bezier2Path addLineToPoint: CGPointMake(12.5 * scale, 13.5 * scale)];
    bezier2Path.lineCapStyle = kCGLineCapRound;
    bezier2Path.lineJoinStyle = kCGLineJoinRound;
    bezier2Path.lineWidth = lineWidth;
    [bezier2Path stroke];
    
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(19.5 * scale, 13.5 * scale)];
    [bezier3Path addLineToPoint: CGPointMake(12.5 * scale, 6.5 * scale)];
    bezier3Path.lineCapStyle = kCGLineCapRound;
    bezier3Path.lineWidth = lineWidth;
    [bezier3Path stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
}

// 绘制折叠键盘图标
- (UIImage *)dismissImageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat lineWidth = 2.f * scale;
    CGSize size = CGSizeMake(38 * scale, 28 * scale);

    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setStroke];
    [color setFill];

    CGContextBeginPath(context);

    // 绘制外部矩形
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(1 * scale, 1 * scale, 36 * scale, 21 * scale)];
    rectanglePath.lineWidth = lineWidth;
    [rectanglePath stroke];
    
    // 绘制底部三角形
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(21.71 * scale, 25 * scale)];
    [bezierPath addLineToPoint: CGPointMake(24 * scale, 25 * scale)];
    [bezierPath addLineToPoint: CGPointMake(20 * scale, 28 * scale)];
    [bezierPath addLineToPoint: CGPointMake(16 * scale, 25 * scale)];
    [bezierPath addLineToPoint: CGPointMake(21.71 * scale, 25 * scale)];
    [bezierPath closePath];
    [bezierPath fill];
    
    // 绘制第一排点1
    UIBezierPath* rectangle02Path = [UIBezierPath bezierPathWithRect: CGRectMake( 5 * scale,  5 * scale, 3 * scale, 3 * scale)];
    [rectangle02Path fill];
    
    // 绘制第一排点2
    UIBezierPath* rectangle03Path = [UIBezierPath bezierPathWithRect: CGRectMake(10 * scale,  5 * scale, 3 * scale, 3 * scale)];
    [rectangle03Path fill];
    
    // 绘制第一排点3
    UIBezierPath* rectangle04Path = [UIBezierPath bezierPathWithRect: CGRectMake(15 * scale,  5 * scale, 3 * scale, 3 * scale)];
    [rectangle04Path fill];
    
    // 绘制第一排点4
    UIBezierPath* rectangle05Path = [UIBezierPath bezierPathWithRect: CGRectMake(20 * scale,  5 * scale, 3 * scale, 3 * scale)];
    [rectangle05Path fill];
    
    // 绘制第一排点5
    UIBezierPath* rectangle06Path = [UIBezierPath bezierPathWithRect: CGRectMake(25 * scale,  5 * scale, 3 * scale, 3 * scale)];
    [rectangle06Path fill];
    
    // 绘制第一排点6
    UIBezierPath* rectangle07Path = [UIBezierPath bezierPathWithRect: CGRectMake(30 * scale,  5 * scale, 3 * scale, 3 * scale)];
    [rectangle07Path fill];
    
    // 绘制第二排点1
    UIBezierPath* rectangle08Path = [UIBezierPath bezierPathWithRect: CGRectMake( 7 * scale, 10 * scale, 3 * scale, 3 * scale)];
    [rectangle08Path fill];
    
    // 绘制第二排点2
    UIBezierPath* rectangle09Path = [UIBezierPath bezierPathWithRect: CGRectMake(12 * scale, 10 * scale, 3 * scale, 3 * scale)];
    [rectangle09Path fill];
    
    // 绘制第二排点3
    UIBezierPath* rectangle10Path = [UIBezierPath bezierPathWithRect: CGRectMake(17 * scale, 10 * scale, 3 * scale, 3 * scale)];
    [rectangle10Path fill];
    
    // 绘制第二排点4
    UIBezierPath* rectangle11Path = [UIBezierPath bezierPathWithRect: CGRectMake(22 * scale, 10 * scale, 3 * scale, 3 * scale)];
    [rectangle11Path fill];
    
    // 绘制第二排点5
    UIBezierPath* rectangle12Path = [UIBezierPath bezierPathWithRect: CGRectMake(27 * scale, 10 * scale, 3 * scale, 3 * scale)];
    [rectangle12Path fill];
    
    // 绘制第三排点1
    UIBezierPath* rectangle13Path = [UIBezierPath bezierPathWithRect: CGRectMake( 6 * scale, 15 * scale, 3 * scale, 3 * scale)];
    [rectangle13Path fill];
    
    // 绘制第三排点2
    UIBezierPath* rectangle14Path = [UIBezierPath bezierPathWithRect: CGRectMake(29 * scale, 15 * scale, 3 * scale, 3 * scale)];
    [rectangle14Path fill];

    // 绘制第三排中间横线
    UIBezierPath* rectangle15Path = [UIBezierPath bezierPathWithRect: CGRectMake(11 * scale, 15 * scale, 16 * scale, 3 * scale)];
    [rectangle15Path fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
}

// 清除光标之前的字符
- (void)clearTextBeforeCursor {
    UIView<UITextInput> *inputView = [UIApplication firstResponder];
    UITextPosition *beginning = inputView.beginningOfDocument;
    UITextPosition *selectionStart = inputView.selectedTextRange.start;
    UITextRange *range = [inputView textRangeFromPosition:beginning toPosition:selectionStart];
    [inputView replaceRange:range withText:@""];
}

// 调用TextField委托方法
- (BOOL)shouldReturn {
    UIView<UITextInput> *firstResponder = [UIApplication firstResponder];
    if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        if (textField.delegate && [textField.delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
            return [textField.delegate textFieldShouldReturn:textField];
        }
    }
    
    return YES;
}

// 调用TextField委托方法
- (BOOL)shouldChangeText:(NSString *)text {
    UIView<UITextInput> *firstResponder = [UIApplication firstResponder];
    if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        if (textField.delegate && [textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            NSRange range = [self selectedRangeInInputView:textField];
            return [textField.delegate textField:textField shouldChangeCharactersInRange:range replacementString:text];
        }
    }
    
    return YES;
}

- (NSRange)selectedRangeInInputView:(id<UITextInput>)inputView {
    UITextPosition *beginning = inputView.beginningOfDocument;
    UITextRange *selectedRange = inputView.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    NSInteger location = [inputView offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [inputView offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

#pragma mark - UIInputViewAudioFeedback

// 要让键盘发声，需要实现该方法
- (BOOL)enableInputClicksWhenVisible {
    return _isClickSound;
}

@end
