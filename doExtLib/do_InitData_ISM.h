//
//  do_InitData_IMethod.h
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol do_InitData_ISM <NSObject>

//实现同步或异步方法，parms中包含了所需用的属性
@required
- (void)copy:(NSArray *)parms;
- (void)copyFile:(NSArray *)parms;
- (void)dirExist:(NSArray *)parms;
- (void)fileExist:(NSArray *)parms;
- (void)getDirs:(NSArray *)parms;
- (void)getFiles:(NSArray *)parms;
- (void)readFile:(NSArray *)parms;
- (void)readFileSync:(NSArray *)parms;
- (void)unzip:(NSArray *)parms;
- (void)zip:(NSArray *)parms;
- (void)zipFiles:(NSArray *)parms;

@end