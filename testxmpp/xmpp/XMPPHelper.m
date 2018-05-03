//
//  XMPPHelper.m
//  HelloCpp-mobile
//
//  Created by gwh on 2017/12/29.
//

#import "XMPPHelper.h"
//#import "ShareCallback.h"

@import XMPPFramework;

@interface XMPPHelper(){
    
}

@property(nonatomic,retain) XMPPJID *jid;
@property(nonatomic,retain) XMPPStream *xmppStream;
@property(nonatomic,retain) XMPPStreamManagement *xmppStreamManagement;
@property(nonatomic,retain) XMPPStreamManagementMemoryStorage *storage;
@property(nonatomic,retain) XMPPReconnect *xmppReconnect;
@property(nonatomic,retain) NSString *userName;
@property(nonatomic,retain) NSString *password;
@property(nonatomic,retain) NSString *hostName;
@property(nonatomic,retain) NSString *domain;
@property(nonatomic,assign) UInt16 hostPort;
@property(nonatomic,retain) NSDictionary *infoDic;
@property(nonatomic,assign) int retryCount;

@end

@implementation XMPPHelper

static XMPPHelper *userManager = nil;
static dispatch_once_t onceToken;

+ (instancetype)getInstance
{
    dispatch_once(&onceToken, ^{
        userManager = [[XMPPHelper alloc] init];
        //        [userManager initCards];
    });
    return userManager;
}

// 取消连接
- (void)disconnect
{
    [self goOffline];
    [_xmppStream disconnect];
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

- (BOOL)connect
{
    if ([self isConnected]) {
//        [ShareCallback xmppCallback:@"success"];
        return YES;
    }
    
    NSError * error = nil;
    //验证连接
    [self.xmppStream connectWithTimeout:5 error:&error];
    if (error) {
        NSLog(@"连接失败：%@",error);
        return NO;
    }
    else
    {
        NSLog(@"连接成功！");
        return  YES;
    }
}

#pragma mark -- connect delegate
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender{
//    [ShareCallback xmppCallback:@"fail"];
}

//输入密码验证登陆
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSError *error = nil;
    [[self xmppStream] authenticateWithPassword:_password error:&error];
}

//登录成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"xmpp登录成功%s",__func__);
    //发送在线通知给服务器，服务器才会将离线消息推送过来
    XMPPPresence *presence = [XMPPPresence presence]; // 默认"available"
    [[self xmppStream] sendElement:presence];
    [_xmppStreamManagement enableStreamManagementWithResumption:YES maxTimeout:10];
    
//    NSXMLElement *enable = [NSXMLElement elementWithName:@"r" xmlns:@"urn:xmpp:sm:3"];
//    [[self xmppStream] sendElement:enable];
    //启用流管理
//    [_xmppStreamManagement enableStreamManagementWithResumption:YES maxTimeout:0];
//    [ShareCallback xmppCallback:@"success"];
    self.retryCount=0;
}

//登陆失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"xmpp登录失败%s",__func__);
//    [ShareCallback xmppPushError:@"resign"];
}

// XMPPMessageArchiving.m
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
//    [ShareCallback xmppPushMsg:messageBody];
//    int su=[_xmppStream supportsStreamManagement];
//    [self sendMessage:@"aaa" to:_jid];
//
//    NSXMLElement *enable = [NSXMLElement elementWithName:@"r" xmlns:@"urn:xmpp:sm:3"];
//    [[self xmppStream] sendElement:enable];
}
- (void)sendMessage:(NSString *)message to:(XMPPJID *)jid
{
    XMPPMessage* newMessage = [[XMPPMessage alloc] initWithType:@"chat" to:jid];
    [newMessage addBody:message]; //消息内容
    [_xmppStream sendElement:newMessage];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
    
}
- (void)xmppStream:(XMPPStream *)sender didSendCustomElement:(NSXMLElement *)element{
    NSLog(@"didSendCustomElement%@",element);
}
- (void)xmppStream:(XMPPStream *)sender didReceiveCustomElement:(NSXMLElement *)element{
    NSLog(@"didReceiveCustomElement%@",element);
}
// 收到错误消息
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    NSLog(@"收到错误消息%@",error);
    
//    [ShareCallback xmppCallback:@"fail"];
//    NSString *errorStr=[NSString stringWithFormat:@"%@",error];
//    if ([errorStr containsString:@"conflict"]) {
//        [ShareCallback xmppPushError:@"resign"];
//    }
    //<stream:error xmlns:stream="http://etherx.jabber.org/streams"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-streams"/></stream:error>
    
//    [ShareCallback xmppPushError:error];
}

// 连接出错8201710268646593
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"error=%@",error);
    if (!error) {//主动？
        return;
    }
    if (self.retryCount<3) {
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds *   NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.retryCount++;
            [self connect];
        });
        return;
    }
    self.retryCount=0;
    if (error.code==57||error.code==7) {
        //连接断开
        //Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={_kCFStreamErrorCodeKey=57, _kCFStreamErrorDomainKey=1}
//        [ShareCallback xmppPushError:@"fail"];
    }else{
//        [ShareCallback xmppPushError:@"others"];
    }
}

//初始化
- (BOOL)initWithUserName:(NSString *)userName andPassword:(NSString *)password andHostName:(NSString *)hostName andDomain:(NSString*)domain andHostPort:(UInt16)hostPort andInfoDic:(NSDictionary *)infoDic
{
    self.hostName = hostName;
    self.hostPort = hostPort;
    self.domain = domain;
    self.userName = userName;
    self.password = password;
    self.infoDic = infoDic;
    self.retryCount=0;
    [self initXMPP];
    return YES;
}

- (void)initXMPP{
    _storage = [XMPPStreamManagementMemoryStorage new];
    
    self.xmppStream = [[XMPPStream alloc] init];
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    //设置聊天服务器地址
    self.xmppStream.hostName = _hostName;
    //设置聊天服务器端口 默认是5222
    self.xmppStream.hostPort = _hostPort;
    
    //设置Jid 就是用户名
    _jid = [XMPPJID jidWithUser:_userName domain:_domain resource:@"smack"];
    self.xmppStream.myJID = _jid;
    
    //接入断线重连模块
    _xmppReconnect = [[XMPPReconnect alloc] init];
    [_xmppReconnect setAutoReconnect:YES];
    [_xmppReconnect activate:self.xmppStream];
    
    //接入流管理模块，用于流恢复跟消息确认，在移动端很重要
    _xmppStreamManagement = [[XMPPStreamManagement alloc] initWithStorage:_storage];
    _xmppStreamManagement.autoResume = YES;
    [_xmppStreamManagement addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppStreamManagement activate:self.xmppStream];
}

- (BOOL)isConnected{
    return [[self xmppStream]isConnected];
}

@end
