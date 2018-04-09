# DSInputKit

### DSNumericKeyboardView

`DSNumericKeyboardView`是一款专用于输入数字相关的键盘视图。

#### 特性

* 支持三种键盘类型：
  * 纯数字键盘（一般用于输入银行卡、短信验证码、数字密码等）
  * 带小数点的数字键盘
  * 身份证键盘
* 支持数字区随机乱序排列
* 支持附件视图
* 支持按键音
* 默认样式仿造支付宝键盘，同时也开放了一些属性来自定义颜色和字体
* 当输入域无内容时，确定按钮会显示未激活状态
* 长按回退键，会连续删除光标之前的字符；长按超过2秒，会清空光标之前的所有字符
* 只有一组源文件，包括相关的图标都是采用代码绘制

#### 截图

参看`Screenshot`目录中的文件

#### 附注

参考并使用了[WLDecimalKeyboard](https://github.com/zhwayne/WLDecimalKeyboard)中的部分代码，尤其是绘制图标的部分，感谢`zhwayne`

