//
//  do_InitData_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_InitData_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doIOHelper.h"
#import "doJsonHelper.h"
#import "doIApp.h"
#import "doIDataFS.h"
#import "doZipArchive.h"
#import "doISourceFS.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"

static NSString *prefix = @"initdata://";
static NSString *prefixTarget = @"data://";

@implementation do_InitData_SM
{
    NSString *_appID;
}
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
- (BOOL)isValidate:(NSString *)path
{
    BOOL is = YES;
    if (!path || path.length == 0 || ![path hasPrefix:prefix]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil : [NSString stringWithFormat:@"路径前缀必须是%@",prefix]];
        is = NO;
    }
    return is;
}

#pragma mark - exist
//同步
- (void)dirExist:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSString *path = [doJsonHelper GetOneText:_dictParas :@"path" :@""];
    //参数字典_dictParas
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    BOOL isValidate = [self isValidate:path];
    if (!isValidate) {
        [_invokeResult SetResultBoolean:isValidate];
        return;
    }

    BOOL isDir = [doIOHelper ExistDirectory:[_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:path]];
    
    [_invokeResult SetResultBoolean:isDir];
}

- (void)fileExist:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSString *path = [doJsonHelper GetOneText:_dictParas :@"path" :@""];
    //参数字典_dictParas
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    //_invokeResult设置返回值
    BOOL isValidate = [self isValidate:path];
    if (!isValidate) {
        [_invokeResult SetResultBoolean:isValidate];
        return;
    }
    
    BOOL isDir = [doIOHelper ExistFile:[_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:path]];
    
    [_invokeResult SetResultBoolean:isDir];
}

#pragma mark - readFile
- (void)readFileSync:(NSArray *)parms
{
    [self readContent:parms :YES];
}
- (void)readFile:(NSArray*) parms
{
    [self readContent:parms :NO];
}
- (void)readContent:(NSArray*) parms :(BOOL)isSync
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    
    doInvokeResult * _invokeResult ;
    NSString* _callbackFuncName;
    
    if (isSync) {
        _invokeResult = [parms objectAtIndex:2];
    }else{
        _callbackFuncName = [parms objectAtIndex:2];
        _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    }
    
    NSString * _filename = [doJsonHelper GetOneText: _dictParas :@"path" :@""];
    if (![self isValidate:_filename]) {
        if (isSync) {
            [_invokeResult SetResultText:@""];
        }else{
            [_invokeResult SetResultText:@""];
            [_scriptEngine Callback:_callbackFuncName :_invokeResult];
        }
        return;
    }
    if(_filename == nil) _filename = @"";
    NSString * blockFilename = [_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:_filename];
    NSString *content = [self getFileContent:blockFilename :_filename];
    
    if (isSync) {
        [_invokeResult SetResultText:content];
    }else{
        [_invokeResult SetResultText:content];
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}
- (NSString *)getFileContent:(NSString *)filename :(NSString *)path
{
    @try{
        NSString * _content = @"";
        _content = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
        if (_content == nil) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"读取的文件不是以utf-8格式编码"];
        }
        return _content;
    }
    @catch(NSException * ex)
    {
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:ex];
        return nil;
    }
}

#pragma mark - copy
//异步
- (void)copy:(NSArray *)parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    // 压缩后文件的名称 (包含路径)
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    // 要进行压缩的源文件路径
    NSArray *_sources = [doJsonHelper GetOneArray:_dictParas :@"source"];
    NSMutableArray* _sourceFull = [[NSMutableArray alloc]init];
    
    @try {
        if (_target.length<=0) {
            [NSException raise:@"InitData" format:@"copy的target参数不能为空"];
        }else if(![_target hasPrefix:prefixTarget]){
            [NSException raise:@"InitData" format:@"copy的target参数只支持%@",prefixTarget];
        }
        if (_sources.count<=0) {
            [NSException raise:@"InitData" format:@"copy的source参数不能为空"];
        }else{
            for (NSString *_source in _sources) {
                if(![_source hasPrefix:prefix]){
                    [NSException raise:@"InitData" format:@"copy的source参数只支持%@",prefix];
                    break;
                }
            }
        }
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        if(![doIOHelper ExistDirectory:_target])
            [doIOHelper CreateDirectory:_target];
        for(int i = 0;i<_sources.count;i++)
        {
            if(_sources[i]!=nil)
            {
                NSString* _temp = [_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:_sources[i]];
                BOOL isDir;
                //目录
                if([[NSFileManager defaultManager] fileExistsAtPath:_temp isDirectory:&isDir] && isDir){
                    [_sourceFull addObject:_temp];
                }
                else
                {
                    //文件
                    if (![doIOHelper ExistFile:_temp]) {
                        continue;
                    }
                    if(_temp!=nil)
                        [_sourceFull addObject:_temp];
                }
            }
        }
        if (_sourceFull.count > 0) {
            for(int i = 0;i<_sourceFull.count;i++)
            {
                BOOL isDir;
                //目录
                if([[NSFileManager defaultManager] fileExistsAtPath:_sourceFull[i] isDirectory:&isDir] && isDir){
                    [doIOHelper DirectoryCopy:_sourceFull[i] :_target];
                }
                else
                {
                    NSString* file = [_sourceFull[i] lastPathComponent];
                    NSString* targetFile =[NSString stringWithFormat:@"%@/%@",_target,file];
                    [doIOHelper FileCopy:_sourceFull[i] : targetFile];
                }
            }
            
            [_invokeResult SetResultBoolean:YES];
        }
        else
        {
            [_invokeResult SetResultBoolean:NO];
        }
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    [_scriptEngine Callback:_callbackFuncName :_invokeResult];
}
- (void)copyFile:(NSArray *)parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    NSString *_source = [doJsonHelper GetOneText:_dictParas :@"source" :@""];
    
    @try {
        if (_target.length<=0) {
            [NSException raise:@"InitData" format:@"copy的target参数不能为空"];
        }else if(![_target hasPrefix:@"data://"]){
            [NSException raise:@"InitData" format:@"copy的target参数只支持%@",prefixTarget];
        }
        if (_source.length<=0) {
            [NSException raise:@"InitData" format:@"copy的source参数不能为空"];
        }else if(![_source hasPrefix:prefix]){
            [NSException raise:@"InitData" format:@"copy的source参数只支持%@",prefix];
        }
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        NSString *_targetFileDic = [_target stringByDeletingLastPathComponent];
        if (![doIOHelper ExistDirectory:_targetFileDic]) {
            [doIOHelper CreateDirectory:_targetFileDic];
        }
        NSString *_sourcePath = [_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:_source];
        [doIOHelper FileCopy:_sourcePath : _target];

        [_invokeResult SetResultBoolean:YES];
    }
    @catch (NSException *exception) {
        [_invokeResult SetResultBoolean:NO];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}

#pragma mark - get
- (void)getFiles:(NSArray*) parms
{
    [self gets:parms :@"file"];
}

- (void)getDirs:(NSArray*) parms
{
    [self gets:parms :@"dir"];
}

- (void)gets:(NSArray*) parms :(NSString *)type
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    NSString * directory =[doJsonHelper GetOneText: _dictParas :@"path" :@""];
    if(directory == nil) directory = @"";
    if (![self isValidate:directory]) {
        [_invokeResult SetResultArray:[NSMutableArray array]];
    }else{
        @try{
            NSString *_dirFullPath = [_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:directory];
                        NSMutableArray * _listAppFiles = [[NSMutableArray alloc] init];
            NSArray * dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_dirFullPath error:nil];
            for (NSString * aPath in dirs) {
                NSString * fullPath = [_dirFullPath stringByAppendingPathComponent:aPath];
                BOOL isDir;
                BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
                if ([type isEqualToString:@"file"]) {
                    if(isExist && !isDir){
                        NSString *returnValue = [NSString stringWithFormat:@"%@",aPath];
                        [_listAppFiles addObject:returnValue];
                    }
                }else
                    if(isExist && isDir){
                        NSString *returnValue = [NSString stringWithFormat:@"%@",aPath];
                        [_listAppFiles addObject:returnValue];
                    }
                
            }
            [_invokeResult SetResultArray:_listAppFiles];
        }@catch (NSException * ex){
            [_invokeResult SetException:ex];
        }@finally {
            
        }
    }
    [_scriptEngine Callback:_callbackFuncName :_invokeResult];
}

#pragma mark - zip
- (void)unzip:(NSArray *)parms
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    // 压缩后文件的名称 (包含路径)
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    // 要进行压缩的源文件路径
    NSString * _source = [doJsonHelper GetOneText: _dictParas :@"source" :@""];
    
    @try {
        if (_target.length<=0) {
            [NSException raise:@"InitData" format:@"unzip的target参数不能为空"];
        }else if(![_target hasPrefix:prefixTarget]){
            [NSException raise:@"InitData" format:@"unzip的target参数只支持%@",prefixTarget];
        }
        if (_source.length<=0) {
            [NSException raise:@"InitData" format:@"unzip的source参数不能为空"];
        }else if(![_source hasPrefix:prefix]){
            [NSException raise:@"InitData" format:@"unzip的source参数只支持%@",prefix];
        }
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        _source = [_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:_source];
        if(![[NSFileManager defaultManager] fileExistsAtPath:_target ])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:_target withIntermediateDirectories:YES attributes:nil error:nil];
        }
        doZipArchive *za = [[doZipArchive alloc] init];
        BOOL success=NO;
        if ([za UnzipOpenFile: _source]) {
            success = [za UnzipFileTo: _target overWrite: YES];
            [za UnzipCloseFile];
        }
        [_invokeResult SetResultBoolean:success];
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}
- (void)zip:(NSArray *)parms
{
    [self zipFiles:parms :@"zip"];
}
- (void)zipFiles:(NSArray *)parms
{
    [self zipFiles:parms :@"zipFiles"];
}

- (void)zipFiles:(NSArray *)parms :(NSString *)type
{
    NSDictionary* _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _callbackFuncName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc ] init:self.UniqueKey];
    
    // 压缩后文件的名称 (包含路径)
    NSString *_target = [doJsonHelper GetOneText: _dictParas :@"target" :@""];
    // 要进行压缩的源文件路径
    NSArray * _sources;
    if ([type isEqualToString:@"zipFiles"]) {
        _sources = [doJsonHelper GetOneArray: _dictParas :@"source"];
    }else{
        NSString *s = [doJsonHelper GetOneText: _dictParas :@"source" :@""];
        _sources = @[s];
    }

    @try {
        if (_target.length<=0) {
            [NSException raise:@"InitData" format:@"target参数不能为空"];
        }else if(![_target hasPrefix:prefixTarget]){
            [NSException raise:@"InitData" format:@"target只能为%@",prefixTarget];
        }
        if (_sources==nil||_sources.count<=0) {
            [NSException raise:@"InitData" format:@"source参数不能为空"];
        }else {
            for (NSString *_source in _sources) {
                if(![_source hasPrefix:prefix]){
                    [NSException raise:@"InitData" format:@"source只能为%@",prefix];
                    break;
                }
            }
        }
        _target = [_scriptEngine.CurrentApp.DataFS GetFileFullPathByName:_target];
        NSString *str = [_target stringByDeletingLastPathComponent];
        if(![[NSFileManager defaultManager] fileExistsAtPath:str ])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
        }
        doZipArchive *za = [[doZipArchive alloc] init];
        [za CreateZipFile2:_target];
        BOOL fileExistsAtPath ;
        for(NSString* _source in _sources){
            NSString* source = [_scriptEngine.CurrentApp.SourceFS GetFileFullPathByName:_source];
            BOOL isDirectory;
            fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:source isDirectory:&isDirectory];
            if(fileExistsAtPath){
                if(isDirectory)
                    [za addFolderToZip:source pathPrefix:nil];
                else
                    [za addFileToZip:source newname:[source lastPathComponent]];
            }
        }
        if(_sources.count==1 && !fileExistsAtPath){
            [_invokeResult SetResultBoolean:NO];
        }else{
            BOOL success = [za CloseZipFile2];
            [_invokeResult SetResultBoolean:success];
        }
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    @finally {
        [_scriptEngine Callback:_callbackFuncName :_invokeResult];
    }
}

@end
