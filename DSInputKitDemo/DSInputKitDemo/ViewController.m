//
//  ViewController.m
//  DSInputKitDemo
//
//  Created by Dragon Sun on 2018/03/29.
//  Copyright © 2018 Dragon Sun. All rights reserved.
//

#import "ViewController.h"
#import "DSNumericKeyboardView.h"


@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *numberInput;
@property (weak, nonatomic) IBOutlet UITextField *decimalInput;
@property (weak, nonatomic) IBOutlet UITextField *idCardInput;
@property (weak, nonatomic) IBOutlet UITextField *propertyInput;
@property (weak, nonatomic) IBOutlet UITextField *accessoryInput;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 数字 (银行卡/验证码等)例子
    DSNumericKeyboardView *numberKeyboard = [[DSNumericKeyboardView alloc] initWithType:DSKeyboardTypeNumber];
    numberKeyboard.isRandomNumericOrder = YES;
    numberKeyboard.done = ^(void) {
        NSLog(@"%s, %@", __func__, @"点击了确认");
    };
    self.numberInput.inputView = numberKeyboard;

    // 小数 (金额等)例子
    DSNumericKeyboardView *decimalKeyboard = [[DSNumericKeyboardView alloc] initWithType:DSKeyboardTypeDecimal];
    self.decimalInput.inputView = decimalKeyboard;
    self.decimalInput.delegate = self;

    // 身份证(有按键声)例子
    DSNumericKeyboardView *idCardKeyboard = [[DSNumericKeyboardView alloc] initWithType:DSKeyboardTypeIDCard];
    idCardKeyboard.isClickSound = YES;
    self.idCardInput.inputView = idCardKeyboard;
    
    // 属性设置例子
    DSNumericKeyboardView *propertyKeyboard = [[DSNumericKeyboardView alloc] initWithType:DSKeyboardTypeNumber];
    propertyKeyboard.viewBackgroundColor = [UIColor magentaColor];
    propertyKeyboard.buttonNormalColor = [UIColor yellowColor];
    propertyKeyboard.buttonHighLightedColor = [UIColor orangeColor];
    propertyKeyboard.doneButtonNormalColor = [UIColor redColor];
    propertyKeyboard.doneButtonDisabledColor = [UIColor cyanColor];
    propertyKeyboard.doneButtonHighLightedColor = [UIColor greenColor];
    propertyKeyboard.buttonFontColor = [UIColor redColor];
    propertyKeyboard.doneButtonFontColor = [UIColor blueColor];
    propertyKeyboard.doneButtonDisabledFontColor = [UIColor whiteColor];
    propertyKeyboard.buttonFont = [UIFont fontWithName:@"CourierNewPS-ItalicMT" size:32.0f];
    propertyKeyboard.doneButtonTitle = @"好";
    self.propertyInput.inputView = propertyKeyboard;

    // 附件视图例子
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"这是附件视图";
    label.backgroundColor = [DSNumericKeyboardView defaultButtonNormalColor];

    UIView *accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
    accessoryView.backgroundColor = [DSNumericKeyboardView defaultViewBackgroundColor];
    [accessoryView addSubview:label];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:accessoryView attribute:NSLayoutAttributeLeft multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:accessoryView attribute:NSLayoutAttributeRight multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:accessoryView attribute:NSLayoutAttributeTop multiplier:1 constant:0.5f].active = YES;
    [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:accessoryView attribute:NSLayoutAttributeBottom multiplier:1 constant:0].active = YES;

    DSNumericKeyboardView *accessoryKeyboard = [[DSNumericKeyboardView alloc] initWithType:DSKeyboardTypeNumber accessoryView:accessoryView];
    self.accessoryInput.inputView = accessoryKeyboard;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSLog(@"%s, %@, %@", __func__, NSStringFromRange(range), string);
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"%s", __func__);
    return YES;
}

@end
