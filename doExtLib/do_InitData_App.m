//
//  do_InitData_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_InitData_App.h"
static do_InitData_App* instance;
@implementation do_InitData_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_InitData_App alloc]init];
    return instance;
}
@end
