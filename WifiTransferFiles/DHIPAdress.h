//
//  DHIPAdress.h
//  WifiTransferFiles
//
//  Created by 张丁豪 on 2017/5/5.
//  Copyright © 2017年 zhangdinghao. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@interface DHIPAdress : NSObject

/*!
 * get device ip address
 */
+ (NSString *)deviceIPAdress;

@end
