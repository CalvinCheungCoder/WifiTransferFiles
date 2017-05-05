//
//  MyHTTPConnection.h
//  iRead
//
//  Created by 张丁豪 on 2017/5/5.
//  Copyright © 2017年 zhangdinghao. All rights reserved.
//


#import "HTTPConnection.h"

@class MultipartFormDataParser;

@interface MyHTTPConnection : HTTPConnection  {
    MultipartFormDataParser*        parser;
    NSFileHandle*					storeFile;
    
    NSMutableArray*					uploadedFiles;
}

@end
