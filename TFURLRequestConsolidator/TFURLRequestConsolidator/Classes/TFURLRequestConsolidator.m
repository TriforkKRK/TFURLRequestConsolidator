/*
 * TFURLRequestConsolidator formely URLDataFetcher
 *
 * Created by Bartlomiej Hyzy  on 02/08/2012.
 * Modified by Krzysztof Profic on 10/04/2014
 * Copyright (c) 2013 Trifork A/S.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "TFURLRequestConsolidator.h"
#import <CommonCrypto/CommonDigest.h>


@interface TFURLRequestConsolidator ()

/** 
    @{
        @"requestKey1" : @[blockA, blockB, ...],
        @"requestKey2" : @[blockC, blockD, blockE, ...],
        ...
    };
 */
@property (strong, nonatomic) NSMutableDictionary * fetchRequestBlocks;

@property (strong, nonatomic) NSMutableDictionary * fetchRequests;

@end


@implementation TFURLRequestConsolidator

#pragma mark - Instance Methods

- (id)fetchRequest:(NSURLRequest *)request userInfo:(id)info completionHandler:(TFURLRequestConsolidatorBlock)completionHandler;
{
    NSParameterAssert(request);
    NSParameterAssert(completionHandler);
    
    // check if data from the url has been already downloaded
    if (self.cacheDelegate != nil) {
        id cachedResponseObject = [self.cacheDelegate requestConsolidator:self cachedResponseObjectForRequest:request userInfo:info];
        if (cachedResponseObject != nil) {
            completionHandler(cachedResponseObject, nil);
            return nil;
        }
    }
    
    // get fetch request key for the URL
    NSString *requestKey = [self fetchRequestKey:request];
    
    // synchronized access to internal objects (fetchRequests & fetchRequestsBlocks)
    @synchronized(self.fetchRequestBlocks) {
        // append block to the fetch request if it already exists
        NSMutableArray *requestBlocks = [self.fetchRequestBlocks objectForKey:requestKey];
        if (requestBlocks != nil) {
            [requestBlocks addObject:[completionHandler copy]];
            return [self.fetchRequests objectForKey:requestKey];
        }
    
        // assign the block to the fetch request
        requestBlocks = [NSMutableArray arrayWithObject:[completionHandler copy]];
        [self.fetchRequestBlocks setObject:requestBlocks forKey:requestKey];
        
        // start asynchronous fetch request
        id requestOperation = [self startFetchRequest:request userInfo:info];
        
        // keep userInfo
        if (requestOperation != nil) {
            [self.fetchRequests setObject:requestOperation forKey:requestKey];
        }
        return requestOperation;
    }
}

#pragma mark - Overriden

- (id)init
{
    NSAssert(NO, @"call initWithRequestDelegate: - request delegate is requried");
    return nil;
}

- (id)initWithRequestDelegate:(id <TFURLRequestConsolidatorDelegate>)delegate
{
    NSAssert(delegate != nil, @"request delegate cannot be nil");
    self = [super init];
    if (self != nil) {
        _fetchRequestBlocks = [[NSMutableDictionary alloc] init];
        _fetchRequests = [[NSMutableDictionary alloc] init];
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Private Methods

- (id)startFetchRequest:(NSURLRequest *)request userInfo:(id)info
{
    __weak typeof(self) blockSelf = self;
    
    return [self.delegate requestConsolidator:self sendRequest:request userInfo:info completionHandler:^(id object, NSError *error) {
        if (object != nil) {
            
            // cache downloaded data if a cache delegate has been specified
            if (blockSelf.cacheDelegate != nil) {
                [blockSelf.cacheDelegate requestConcolidator:blockSelf cacheResponseObject:object forRequest:request userInfo:info];
            }
        }
        
        NSString *requestKey = [self fetchRequestKey:request];
        
        // get a list of blocks to call (synchronized because NSOperationQueue may call this
        // operation block from multiple threads concurrently)
        NSMutableArray *requestBlocks;
        // synchronize access to fetch requests array from multiple threads
        @synchronized (blockSelf.fetchRequestBlocks) {
            requestBlocks = [blockSelf.fetchRequestBlocks objectForKey:requestKey];
            [blockSelf.fetchRequestBlocks removeObjectForKey:requestKey];
        }
        
        // call all request blocks, send downloaded data even if nil (error)
        for (TFURLRequestConsolidatorBlock requestBlock in requestBlocks) {
            requestBlock(object, error);
        } 
    }];
}

- (NSString *)fetchRequestKey:(NSURLRequest *)request
{
    return [self MD5HashOfString:request.URL.absoluteString];
}

- (NSString *)MD5HashOfString:(NSString *)string
{
    const char* str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (uint32_t)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end
