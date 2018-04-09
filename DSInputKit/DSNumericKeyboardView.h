//
//  DSNumericKeyboardView.h
//  DSInputKitDemo
//
//  Created by Dragon Sun on 2018/03/29.
//  Copyright © 2018 Dragon Sun. All rights reserved.
//

/*
    没有换行键，不支持UITextView(相关委托方法没有进行处理)
 
           键盘布局                       tag值
     ┌───┬───┬───┬────┐         ┌────┬────┬────┬────┐
     │ 1 │ 2 │ 3 │    │         │  1 │  2 │  3 │    │
     ├───┼───┼───┤ BS │         ├────┼────┼────┤ 14 │
     │ 4 │ 5 │ 6 │    │         │  4 │  5 │  6 │    │
     ├───┼───┼───┼────┤         ├────┼────┼────┼────┤
     │ 7 │ 8 │ 9 │    │         │  7 │  8 │  9 │    │
     ├───┼───┼───┤Done│         ├────┼────┼────┤ 15 │
     │ . │ 0 │ ↓ │    │         │ 10 │  0 │ 13 │    │
     └───┴───┴───┴────┘         └────┴────┴────┴────┘
       X                          11
  placeHolder                     12
 
 */


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DSKeyboardType) {
    DSKeyboardTypeNumber,       // 数字键盘
    DSKeyboardTypeDecimal,      // 金额键盘(多一个.)
    DSKeyboardTypeIDCard,       // 身份证键盘(多一个X)
};


@interface DSNumericKeyboardView : UIView

- (instancetype)initWithType:(DSKeyboardType)keyboardType;
- (instancetype)initWithType:(DSKeyboardType)keyboardType accessoryView:(nullable UIView *)accessoryView NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, nullable) void (^done)(void);                       // 点击了确认按钮的回调

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@property (nonatomic, readonly) DSKeyboardType  keyboardType;                   // 键盘类型
@property (nonatomic, readonly) UIView          *accessoryView;                 // 附件视图
@property (nonatomic, strong)   UIColor         *viewBackgroundColor;           // 分割线颜色(也可以直接设置BackgroundColor属性)
@property (nonatomic, strong)   UIColor         *buttonNormalColor;             // 一般按钮背景的NormalColor
@property (nonatomic, strong)   UIColor         *buttonHighLightedColor;        // 一般按钮背景的HighLightedColor
@property (nonatomic, strong)   UIColor         *buttonFontColor;               // 一般按钮字体颜色
@property (nonatomic, strong)   UIColor         *doneButtonNormalColor;         // 确定按钮背景的NormalColor
@property (nonatomic, strong)   UIColor         *doneButtonDisabledColor;       // 确定按钮背景的DisabledColor
@property (nonatomic, strong)   UIColor         *doneButtonHighLightedColor;    // 确定按钮背景的HighlightedColor
@property (nonatomic, strong)   UIColor         *doneButtonFontColor;           // 确定按钮字体颜色
@property (nonatomic, strong)   UIColor         *doneButtonDisabledFontColor;   // 确定按钮Disabled时的字体颜色
@property (nonatomic, copy)     NSString        *doneButtonTitle;               // 确认按钮标题文字(默认：@"确定")
@property (nonatomic, strong)   UIFont          *buttonFont;                    // 按钮字体(默认：HelveticaNeue, 25)
@property (nonatomic, assign)   BOOL            isClickSound;                   // 是否有按键声(默认：NO)
@property (nonatomic, assign)   BOOL            isRandomNumericOrder;           // 是否数字乱序(默认：NO)

+ (UIColor *)defaultViewBackgroundColor;
+ (UIColor *)defaultButtonNormalColor;
+ (UIColor *)defaultButtonHighLightedColor;
+ (UIColor *)defaultButtonFontColor;
+ (UIColor *)defaultDoneButtonNormalColor;
+ (UIColor *)defaultDoneButtonDisabledColor;
+ (UIColor *)defaultDoneButtonHighLightedColor;
+ (UIColor *)defaultDoneButtonFontColor;
+ (UIColor *)defaultDoneButtonDisabledFontColor;
+ (NSString *)defaultDoneButtonTitle;
+ (NSString *)defaultButtonFontName;
+ (CGFloat)defaultButtonFontSize;

@end
