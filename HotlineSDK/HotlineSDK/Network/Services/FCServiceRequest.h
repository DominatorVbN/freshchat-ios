//
//  HLServiceRequest.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 10/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLMultipartFormData;

@protocol HLMultipartFormData

-(void)addTextPart:(NSString *)text name:(NSString *)name;

/**
 Appends the HTTP headers `Content-Disposition: form-data; name=#{name}"`, followed by the encoded data and the multipart form boundary.
 
 data: The data to be encoded and appended to the form data.
 name: The name to be associated with the specified data. This parameter must not be `nil`. */

- (void)addPart:(NSData *)data name:(NSString *)name;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 data: The data to be encoded and appended to the form data.
 name: The name to be associated with the specified data. This parameter must not be `nil`.
 fileName: The filename to be associated with the specified data. This parameter must not be `nil`.
 mimeType: The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) */

- (void)addFilePart:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

@end

@interface FCServiceRequest : NSMutableURLRequest<HLMultipartFormData>

@property(nonatomic, strong, readonly) NSURL *baseURL;

-(instancetype)initWithBaseURL:(NSURL *)baseURL andMethod:(NSString *)httpMethod;

//contains hard coded URL of hotline -- add more doc
-(instancetype)initWithMethod:(NSString *)httpMethod;

-(instancetype)initMultipartFormRequestWithBody:(void (^)(id <HLMultipartFormData> formData))block;

-(void)setRelativePath:(NSString *)path andURLParams:(NSArray *)params;

-(void)setBody:(NSData *)body;

-(NSString *)toString;

@end
