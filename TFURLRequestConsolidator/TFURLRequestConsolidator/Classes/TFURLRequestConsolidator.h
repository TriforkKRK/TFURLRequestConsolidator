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

#import <Foundation/Foundation.h>

@class TFURLRequestConsolidator;


/**
    Block type for TFURLRequestConsolidator callback.
    @param object data downloaded from the specified URL converted to an object or NSData (may be nil if error occurred)
    @param error error that occurred during request (nil if data was read from cache or request was successful)
 */
typedef void (^TFURLRequestConsolidatorBlock)(id object, NSError *error);


@protocol TFURLRequestConsolidatorDelegate <NSObject>
@required

/**
 * The delegate is asked to handle a request on behalf of a TFURLRequestConsolidator instance.
 * @param consolidator instance of TFURLRequestConsolidator asking the request to be sent
 * @param request request to be sent
 * @param userInfo additional data passed to |consolidator| when |request| was made
 * @param completionHandler completion block that should be called by the delegate after handling |request|
 * @return a reference to requestOperation, it can be anything that repreents a work unit that processes this request. May be nil.
 */
- (id)requestConsolidator:(TFURLRequestConsolidator *)consolidator sendRequest:(NSURLRequest *)request userInfo:(id)userInfo completionHandler:(TFURLRequestConsolidatorBlock)completionHandler;

@end


/**
    Protocol for classes that want to act as a cache for TFURLRequestConsolidator instances.
    Important: Implementation of these methods is expected to be thread-safe.
 */
@protocol TFURLRequestConsolidatorCacheDelegate <NSObject>
@required

/**
    Returns data cached for the specified request.
    @param consolidator instance of TFURLRequestConsolidator requesting cached data
    @param request request of the cached data
    @param userInfo additional data passed to |consolidator| when |request| was made
    @returns response object cached for specified request or nil if no such data
 */
- (id)requestConsolidator:(TFURLRequestConsolidator *)consolidator cachedResponseObjectForRequest:(NSURLRequest *)request userInfo:(NSDictionary *)userInfo;

/**
    Caches data for the specified request for later retrieval.
    @param consolidator instance of TFURLRequestConsolidator asking the response object to be cached
    @param object response object to be cached
    @param request request of the data to be cached
    @param userInfo additional data passed to |consolidator| when |request| was made
 */
- (void)requestConcolidator:(TFURLRequestConsolidator *)consolidator cacheResponseObject:(id)object forRequest:(NSURLRequest *)request userInfo:(NSDictionary *)userInfo;

@end


/**
    Simple data fetcher that can download any type of data for specified request
    and protect from multiple simultanous downloads of the same file.
    It can also redirect data fetch calls to a cache improving performance
    and reducing bandwidth usage.
 
    TODO: we could change the request delegate to be optional and in a case when it is not set use just standard NSURLConnection to get this resource.
 */
@interface TFURLRequestConsolidator : NSObject

/**
    Request delegate responsible for downloading content of resources specified by URLRequests.
 */
@property (nonatomic, weak, readonly) id <TFURLRequestConsolidatorDelegate> delegate;

/**
    Cache object used for caching data. If nil no caching takes place and
    data is downloaded for each subsequent fetch request.
 */
@property (nonatomic, weak, readwrite) id <TFURLRequestConsolidatorCacheDelegate> cacheDelegate;

/**
    Initializes an instance with specified request delegate.
    This is the designated initializer.
    @param delegate delegate responsible for downloading actual data (required, cannot be nil)
 */
- (id)initWithRequestDelegate:(id <TFURLRequestConsolidatorDelegate>)delegate;

/**
    Retrieves data from URL and passes it to the specified block afterwards.
    If the requested data is cached, that happens immediately.
    @param request already configured URLRequest
    @param completionHandler block to call after retrieving the data; if failed nil is passed as the data
    @return a reference to requestOperation, it can be anything that repreents a work unit that processes this request. May be nil if delegate had returned nil.
 */
- (id)fetchRequest:(NSURLRequest *)request userInfo:(id)info completionHandler:(TFURLRequestConsolidatorBlock)completionHandler;

@end
