##大掌柜代码说明

###1.XMPPFramework
	
	XMPP协议iOS实现
	XMPPNetworkCenter.h  封装App和XMPP server 的网络接口
	消息体采用XML编码格式
	
###2.WSBubbleData
	
	model驱动的,气泡对话显示,
	支持拥护互相发布图片，存储在upyun
	支持2种模版的信息格式，图文消息。
	
	
###3.Godzippa

	数据压缩，然后采用AES加密，自定义密钥

###4.POApinyin

	联系人中文名字首字母，英文缩写

###5.CuteData

	数据跟踪
	支持事件和时间统计事件，可以保存参数
	pushView的动作统计
	
	上传机制，第二次打开App时，如果检测到有未上传的log,自动压缩加密上传然后清空log
	

###6.BBCustomBackButtonViewController
	
	可以自己定制 BarButtonItem 和 NavigationBar背景 的类
	viewController 直接继承自 BBCustom,不用继承自UIViewController

##UI结构说明

没有采用tabViewController,主View 是 MainViewController

1. 将各个 子ViewController 在AppDelegate中定义好

2. 在 MainViewController 中实例化各个 子ViewController
3. 在子或者更低一级别的ViewController 中
    [self.navigationController popToRootViewControllerAnimated:NO];
返回MainViewController

MainViewController - calcRect 控制主页面色块的显示