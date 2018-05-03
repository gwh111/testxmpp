//
//  XMPPHelper.h
//  HelloCpp-mobile
//
//  Created by gwh on 2017/12/29.
//

#import <Foundation/Foundation.h>

@interface XMPPHelper : NSObject

//@property(nonatomic,assign) BOOL isConnecting;

+ (instancetype)getInstance;

- (BOOL)initWithUserName:(NSString *)userName andPassword:(NSString *)password andHostName:(NSString *)hostName andDomain:(NSString*)domain andHostPort:(UInt16)hostPort andInfoDic:(NSDictionary *)infoDic;

- (BOOL)connect;

- (void)disconnect;

- (BOOL)isConnected;

@end
